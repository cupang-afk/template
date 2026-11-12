//go:build windows

package main

import (
	"os"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

var (
	modUser32   = syscall.NewLazyDLL("user32.dll")
	modKernel32 = syscall.NewLazyDLL("kernel32.dll")

	procEnumWindows              = modUser32.NewProc("EnumWindows")
	procGetWindowThreadProcessID = modUser32.NewProc("GetWindowThreadProcessId")
	procIsWindowVisible          = modUser32.NewProc("IsWindowVisible")
	procGetWindow                = modUser32.NewProc("GetWindow")
	procIsIconic                 = modUser32.NewProc("IsIconic")
	procShowWindow               = modUser32.NewProc("ShowWindow")
	procGetForegroundWindow      = modUser32.NewProc("GetForegroundWindow")
	procAttachThreadInput        = modUser32.NewProc("AttachThreadInput")
	procBringWindowToTop         = modUser32.NewProc("BringWindowToTop")
	procSetForegroundWindow      = modUser32.NewProc("SetForegroundWindow")
	procSetActiveWindow          = modUser32.NewProc("SetActiveWindow")
	procSetFocus                 = modUser32.NewProc("SetFocus")
	procSwitchToThisWindow       = modUser32.NewProc("SwitchToThisWindow")
	procGetAsyncKeyState         = modUser32.NewProc("GetAsyncKeyState")
	procGetClassNameW            = modUser32.NewProc("GetClassNameW")
	procMessageBoxW              = modUser32.NewProc("MessageBoxW")

	procGetCurrentThreadID       = modKernel32.NewProc("GetCurrentThreadId")
	procCreateToolhelp32Snapshot = modKernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32FirstW          = modKernel32.NewProc("Process32FirstW")
	procProcess32NextW           = modKernel32.NewProc("Process32NextW")
	procWaitNamedPipeW           = modKernel32.NewProc("WaitNamedPipeW")
)

const (
	gwOwner           = 4
	swRestore         = 9
	th32csSnapProcess = 0x00000002
	vkShift           = 0x10

	mbYesNoCancel   = 0x00000003
	mbIconQuestion  = 0x00000020
	mbSetForeground = 0x00010000
	mbIconError     = 0x00000010

	idCancel = 2
	idYes    = 6
)

type processEntry32 struct {
	Size            uint32
	CntUsage        uint32
	ProcessID       uint32
	DefaultHeapID   uintptr
	ModuleID        uint32
	CntThreads      uint32
	ParentProcessID uint32
	PriClassBase    int32
	Flags           uint32
	ExeFile         [syscall.MAX_PATH]uint16
}

var (
	enumMu   sync.Mutex
	enumOnce sync.Once
	enumProc uintptr
	enumFunc func(syscall.Handle) bool
)

// enumWindows walks top-level windows. syscall.NewCallback may only be created
// a limited number of times, so the trampoline is built once and dispatched
// through enumFunc.
func enumWindows(fn func(syscall.Handle) bool) {
	enumOnce.Do(func() {
		enumProc = syscall.NewCallback(func(hwnd uintptr, _ uintptr) uintptr {
			if enumFunc != nil && enumFunc(syscall.Handle(hwnd)) {
				return 1
			}
			return 0
		})
	})

	enumMu.Lock()
	enumFunc = fn
	procEnumWindows.Call(enumProc, 0)
	enumFunc = nil
	enumMu.Unlock()
}

func isVisible(window syscall.Handle) bool {
	ok, _, _ := procIsWindowVisible.Call(uintptr(window))
	return ok != 0
}

func owner(window syscall.Handle) syscall.Handle {
	handle, _, _ := procGetWindow.Call(uintptr(window), gwOwner)
	return syscall.Handle(handle)
}

func windowPID(window syscall.Handle) uint32 {
	var pid uint32
	procGetWindowThreadProcessID.Call(uintptr(window), uintptr(unsafe.Pointer(&pid)))
	return pid
}

func focusWindow(window syscall.Handle) {
	if window == 0 {
		return
	}

	// Only restore a minimized window. Calling ShowWindow(SW_SHOW) on a visible
	// window can un-maximize it.
	if iconic, _, _ := procIsIconic.Call(uintptr(window)); iconic != 0 {
		procShowWindow.Call(uintptr(window), swRestore)
	}

	foreground, _, _ := procGetForegroundWindow.Call()
	var foregroundThread uintptr
	if foreground != 0 {
		foregroundThread, _, _ = procGetWindowThreadProcessID.Call(foreground, 0)
	}
	currentThread, _, _ := procGetCurrentThreadID.Call()

	attached := false
	if foregroundThread != 0 && foregroundThread != currentThread {
		if ok, _, _ := procAttachThreadInput.Call(currentThread, foregroundThread, 1); ok != 0 {
			attached = true
		}
	}

	procBringWindowToTop.Call(uintptr(window))
	procSetForegroundWindow.Call(uintptr(window))
	procSetActiveWindow.Call(uintptr(window))
	procSetFocus.Call(uintptr(window))

	if attached {
		procAttachThreadInput.Call(currentThread, foregroundThread, 0)
	}

	// The foreground lock can still reject SetForegroundWindow. SwitchToThisWindow
	// is what the taskbar and Alt+Tab use, and works without foreground rights.
	if foreground, _, _ = procGetForegroundWindow.Call(); foreground != uintptr(window) {
		procSwitchToThisWindow.Call(uintptr(window), 1)
	}
}

func parentPid(pid uint32) uint32 {
	snapshot, _, _ := procCreateToolhelp32Snapshot.Call(th32csSnapProcess, 0)
	if snapshot == uintptr(syscall.InvalidHandle) {
		return 0
	}
	defer syscall.CloseHandle(syscall.Handle(snapshot))

	var entry processEntry32
	entry.Size = uint32(unsafe.Sizeof(entry))

	ok, _, _ := procProcess32FirstW.Call(snapshot, uintptr(unsafe.Pointer(&entry)))
	for ok != 0 {
		if entry.ProcessID == pid {
			return entry.ParentProcessID
		}
		entry.Size = uint32(unsafe.Sizeof(entry))
		ok, _, _ = procProcess32NextW.Call(snapshot, uintptr(unsafe.Pointer(&entry)))
	}
	return 0
}

func findWindowByPID(pid uint32) syscall.Handle {
	var found syscall.Handle
	enumWindows(func(window syscall.Handle) bool {
		if windowPID(window) == pid && isVisible(window) && owner(window) == 0 {
			found = window
			return false
		}
		return true
	})
	return found
}

// focusInstance walks up the process tree because the server is owned by the
// embedded nvim process, while the visible window belongs to Neovide. Shims can
// separate the two.
func focusInstance(server string) {
	pid := uint32(pidFromServer(server))
	if pid == 0 {
		return
	}

	for depth := 0; depth < 16 && pid != 0 && pid != 4; depth++ {
		if window := findWindowByPID(pid); window != 0 {
			focusWindow(window)
			return
		}

		parent := parentPid(pid)
		if parent == pid {
			return
		}
		pid = parent
	}
}

// focusNewInstance polls for a window owned by the spawned process or one of
// its descendants, then brings it forward.
func focusNewInstance(root int) {
	if root == 0 {
		return
	}

	for attempt := 0; attempt < 100; attempt++ {
		var found syscall.Handle
		enumWindows(func(window syscall.Handle) bool {
			if !isVisible(window) || owner(window) != 0 {
				return true
			}

			current := windowPID(window)
			for current != 0 && current != 4 {
				if int(current) == root {
					found = window
					return false
				}
				parent := parentPid(current)
				if parent == 0 || parent == current {
					break
				}
				current = parent
			}
			return true
		})

		if found != 0 {
			focusWindow(found)
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
}

func shiftHeld() bool {
	state, _, _ := procGetAsyncKeyState.Call(vkShift)
	return state&0x8000 != 0
}

func promptNewInstance() choice {
	// MessageBoxW blocks its caller, so bring the dialog forward from a goroutine.
	go focusDialog(uint32(os.Getpid()))

	result, _, _ := procMessageBoxW.Call(
		0,
		utf16Ptr("Shift key is held.\n\nOpen in a new Neovide instance?"),
		utf16Ptr("Neovide"),
		mbYesNoCancel|mbIconQuestion|mbSetForeground,
	)

	switch uint32(result) {
	case idYes:
		return choiceYes
	case idCancel:
		return choiceCancel
	default:
		return choiceNo
	}
}

func focusDialog(pid uint32) {
	for attempt := 0; attempt < 50; attempt++ {
		var found syscall.Handle
		enumWindows(func(window syscall.Handle) bool {
			if windowPID(window) != pid || !isVisible(window) {
				return true
			}

			var class [16]uint16
			length, _, _ := procGetClassNameW.Call(
				uintptr(window),
				uintptr(unsafe.Pointer(&class[0])),
				uintptr(len(class)),
			)
			if length > 0 && syscall.UTF16ToString(class[:length]) == "#32770" {
				found = window
				return false
			}
			return true
		})

		if found != 0 {
			focusWindow(found)
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
}

func notifyError(title, message string) {
	procMessageBoxW.Call(0, utf16Ptr(message), utf16Ptr(title), mbIconError)
}

func utf16Ptr(value string) uintptr {
	ptr, _ := syscall.UTF16PtrFromString(value)
	return uintptr(unsafe.Pointer(ptr))
}
