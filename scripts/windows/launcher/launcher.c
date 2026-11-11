#define WIN32_LEAN_AND_MEAN
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <wchar.h>

#if defined(__TINYC__)
/* TinyCC ships no tlhelp32.h; declare the ANSI process snapshot API. */
#ifndef TH32CS_SNAPPROCESS
#define TH32CS_SNAPPROCESS 0x00000002
#endif
typedef struct tagPROCESSENTRY32 {
    DWORD dwSize;
    DWORD cntUsage;
    DWORD th32ProcessID;
    ULONG_PTR th32DefaultHeapID;
    DWORD th32ModuleID;
    DWORD cntThreads;
    DWORD th32ParentProcessID;
    LONG pcPriClassBase;
    DWORD dwFlags;
    CHAR szExeFile[MAX_PATH];
} PROCESSENTRY32;
typedef PROCESSENTRY32 *LPPROCESSENTRY32;
HANDLE WINAPI CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
BOOL WINAPI Process32First(HANDLE hSnapshot, LPPROCESSENTRY32 lppe);
BOOL WINAPI Process32Next(HANDLE hSnapshot, LPPROCESSENTRY32 lppe);
#else
#include <tlhelp32.h>
#endif

#define ACTIVE_PIPE_FILE L"neovide_active.pipe"
#define FALLBACK_PIPE L"\\\\.\\pipe\\neovide"
#define NEOVIM_EXE L"nvim.exe"
#define MAX_COMMAND_LENGTH 32768

#ifdef _MSC_VER
#pragma comment(lib, "user32.lib")
#endif

typedef LPWSTR * (WINAPI *CommandLineToArgvWProc)(LPCWSTR, int *);

static LPWSTR *GetCommandLineArgs(int *argc) {
    HMODULE shell32 = LoadLibraryW(L"shell32.dll");
    CommandLineToArgvWProc proc;

    if (!shell32) {
        return NULL;
    }

    proc = (CommandLineToArgvWProc)GetProcAddress(shell32, "CommandLineToArgvW");
    if (!proc) {
        return NULL;
    }

    return proc(GetCommandLineW(), argc);
}

static void AppendString(wchar_t *dst, size_t cap, const wchar_t *src) {
    size_t len = 0;
    while (dst[len]) {
        len++;
    }
    while (*src && len + 1 < cap) {
        dst[len++] = *src++;
    }
    dst[len] = L'\0';
}

static void AppendQuotedArg(wchar_t *dst, size_t cap, const wchar_t *arg) {
    size_t len = 0;
    while (dst[len]) {
        len++;
    }
    if (len > 0 && len + 1 < cap) {
        dst[len++] = L' ';
        dst[len] = L'\0';
    }
    AppendString(dst, cap, L"\"");
    AppendString(dst, cap, arg);
    AppendString(dst, cap, L"\"");
}

static DWORD RunProcessWait(const wchar_t *cmd) {
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    wchar_t cmdBuf[MAX_COMMAND_LENGTH];
    DWORD exitCode = (DWORD)-1;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    lstrcpynW(cmdBuf, cmd, MAX_COMMAND_LENGTH);

    if (!CreateProcessW(NULL, cmdBuf, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
        return (DWORD)-1;
    }

    WaitForSingleObject(pi.hProcess, 4000);
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return exitCode;
}

static DWORD RunProcessDetached(const wchar_t *cmd) {
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    wchar_t cmdBuf[MAX_COMMAND_LENGTH];
    DWORD pid = 0;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    lstrcpynW(cmdBuf, cmd, MAX_COMMAND_LENGTH);

    if (CreateProcessW(NULL, cmdBuf, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        pid = pi.dwProcessId;
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    }
    return pid;
}

static int ProbePipe(const wchar_t *pipeName) {
    if (!pipeName || pipeName[0] == L'\0') {
        return 0;
    }
    return WaitNamedPipeW(pipeName, 80) || GetLastError() == ERROR_PIPE_BUSY;
}

static int GetActivePipe(wchar_t *outPipe, DWORD maxLen) {
    wchar_t tempPath[MAX_PATH];
    wchar_t activeFilePath[MAX_PATH];

    if (GetTempPathW(MAX_PATH, tempPath) > 0) {
        activeFilePath[0] = L'\0';
        AppendString(activeFilePath, MAX_PATH, tempPath);
        AppendString(activeFilePath, MAX_PATH, ACTIVE_PIPE_FILE);

        HANDLE hFile = CreateFileW(activeFilePath, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                                   NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        if (hFile != INVALID_HANDLE_VALUE) {
            char buf[512];
            DWORD bytesRead = 0;

            if (ReadFile(hFile, buf, sizeof(buf) - 1, &bytesRead, NULL) && bytesRead > 0) {
                buf[bytesRead] = '\0';
                while (bytesRead > 0 &&
                       (buf[bytesRead - 1] == '\r' || buf[bytesRead - 1] == '\n' || buf[bytesRead - 1] == ' ')) {
                    buf[--bytesRead] = '\0';
                }

                {
                    DWORD i;
                    for (i = 0; i < bytesRead && i + 1 < maxLen; i++) {
                        outPipe[i] = (wchar_t)(unsigned char)buf[i];
                    }
                    outPipe[i] = L'\0';
                }
                if (ProbePipe(outPipe)) {
                    CloseHandle(hFile);
                    return 1;
                }
            }
            CloseHandle(hFile);
        }
    }

    if (ProbePipe(FALLBACK_PIPE)) {
        lstrcpynW(outPipe, FALLBACK_PIPE, (int)maxLen);
        return 1;
    }

    return 0;
}

static DWORD PipePid(const wchar_t *pipeName) {
    const wchar_t *digits = wcsstr(pipeName, L"neovide_");
    DWORD pid = 0;

    if (!digits) {
        return 0;
    }

    digits += 8;
    while (*digits >= L'0' && *digits <= L'9') {
        pid = pid * 10 + (DWORD)(*digits - L'0');
        digits++;
    }
    return pid;
}

typedef struct {
    DWORD pid;
    HWND window;
} WindowSearch;

static BOOL CALLBACK FindProcessWindow(HWND window, LPARAM param) {
    WindowSearch *search = (WindowSearch *)param;
    DWORD pid = 0;

    GetWindowThreadProcessId(window, &pid);
    if (pid == search->pid && IsWindowVisible(window) && GetWindow(window, GW_OWNER) == NULL) {
        search->window = window;
        return FALSE;
    }
    return TRUE;
}

static DWORD ParentPid(DWORD pid) {
    HANDLE snapshot;
    PROCESSENTRY32 entry;
    DWORD parent = 0;

    snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) {
        return 0;
    }

    entry.dwSize = sizeof(entry);
    if (Process32First(snapshot, &entry)) {
        do {
            if (entry.th32ProcessID == pid) {
                parent = entry.th32ParentProcessID;
                break;
            }
        } while (Process32Next(snapshot, &entry));
    }

    CloseHandle(snapshot);
    return parent;
}

static void FocusWindow(HWND window) {
    DWORD foregroundThread;
    DWORD currentThread;
    BOOL attached = FALSE;

    if (!window) {
        return;
    }

    // Only restore a minimized window. Calling ShowWindow(SW_SHOW) on a visible
    // window can un-maximize it.
    if (IsIconic(window)) {
        ShowWindow(window, SW_RESTORE);
    }

    foregroundThread = GetWindowThreadProcessId(GetForegroundWindow(), NULL);
    currentThread = GetCurrentThreadId();
    if (foregroundThread != 0 && foregroundThread != currentThread) {
        attached = AttachThreadInput(currentThread, foregroundThread, TRUE);
    }

    BringWindowToTop(window);
    SetForegroundWindow(window);
    SetActiveWindow(window);
    SetFocus(window);

    if (attached) {
        AttachThreadInput(currentThread, foregroundThread, FALSE);
    }

    // The foreground lock can still reject SetForegroundWindow. SwitchToThisWindow
    // is what the taskbar and Alt+Tab use, and works without foreground rights.
    if (GetForegroundWindow() != window) {
        SwitchToThisWindow(window, TRUE);
    }
}

static void FocusInstance(const wchar_t *pipeName) {
    WindowSearch search;
    DWORD pid = PipePid(pipeName);
    int depth;

    if (pid == 0) {
        return;
    }

    // The pipe belongs to the embedded nvim process, but the visible window
    // belongs to Neovide. The two may be separated by shim processes, so walk
    // up the process tree until an ancestor owns a visible top-level window.
    search.window = NULL;
    for (depth = 0; depth < 16 && pid != 0 && pid != 4; depth++) {
        DWORD parent;

        search.pid = pid;
        search.window = NULL;
        EnumWindows(FindProcessWindow, (LPARAM)&search);
        if (search.window) {
            break;
        }

        parent = ParentPid(pid);
        if (parent == pid) {
            break;
        }
        pid = parent;
    }

    FocusWindow(search.window);
}

typedef struct {
    DWORD root;
    HWND window;
} DescendantSearch;

static BOOL CALLBACK FindDescendantWindow(HWND window, LPARAM param) {
    DescendantSearch *search = (DescendantSearch *)param;
    DWORD pid = 0;
    DWORD current;

    GetWindowThreadProcessId(window, &pid);
    if (pid == 0 || !IsWindowVisible(window) || GetWindow(window, GW_OWNER) != NULL) {
        return TRUE;
    }

    // The spawned process may be a shim that starts the real executable, so a
    // window qualifies when its owner is the spawned process or any descendant.
    current = pid;
    while (current != 0 && current != 4) {
        DWORD parent;

        if (current == search->root) {
            search->window = window;
            return FALSE;
        }

        parent = ParentPid(current);
        if (parent == 0 || parent == current) {
            break;
        }
        current = parent;
    }

    return TRUE;
}

static void FocusNewInstance(DWORD rootPid) {
    int attempt;

    if (rootPid == 0) {
        return;
    }

    // The new process needs time to create its window. Poll the spawned process
    // and its descendants until one owns a visible top-level window.
    for (attempt = 0; attempt < 100; attempt++) {
        DescendantSearch search;

        search.root = rootPid;
        search.window = NULL;
        EnumWindows(FindDescendantWindow, (LPARAM)&search);
        if (search.window) {
            FocusWindow(search.window);
            return;
        }

        Sleep(100);
    }
}

typedef struct {
    DWORD pid;
    HWND window;
} DialogSearch;

static BOOL CALLBACK FindDialogWindow(HWND window, LPARAM param) {
    DialogSearch *search = (DialogSearch *)param;
    DWORD pid = 0;
    wchar_t className[16];

    GetWindowThreadProcessId(window, &pid);
    if (pid != search->pid || !IsWindowVisible(window)) {
        return TRUE;
    }
    if (GetClassNameW(window, className, 16) == 0) {
        return TRUE;
    }
    if (lstrcmpW(className, L"#32770") == 0) {
        search->window = window;
        return FALSE;
    }
    return TRUE;
}

static DWORD WINAPI FocusDialogThread(LPVOID param) {
    DWORD pid = (DWORD)(DWORD_PTR)param;
    int attempt;

    // MessageBoxW blocks its caller, so this thread waits for the dialog to
    // appear and brings it to the foreground.
    for (attempt = 0; attempt < 50; attempt++) {
        DialogSearch search;

        search.pid = pid;
        search.window = NULL;
        EnumWindows(FindDialogWindow, (LPARAM)&search);
        if (search.window) {
            FocusWindow(search.window);
            return 0;
        }
        Sleep(100);
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd) {
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nShowCmd;

    int argc = 0;
    LPWSTR *argv = GetCommandLineArgs(&argc);
    if (!argv) {
        return 1;
    }

    if (argc < 2) {
        MessageBoxW(NULL, L"Usage: neovide-launcher.exe <neovide.exe> [args...]",
                    L"Neovide Launcher", MB_OK | MB_ICONERROR);
        LocalFree(argv);
        return 1;
    }

    // argv[1] is the launcher's target; argv[2..] are forwarded to Neovide.
    const wchar_t *neovideExe = argv[1];
    const wchar_t *fileArg = (argc > 2) ? argv[2] : NULL;

    wchar_t spawnCmd[MAX_COMMAND_LENGTH];
    spawnCmd[0] = L'\0';
    AppendQuotedArg(spawnCmd, MAX_COMMAND_LENGTH, neovideExe);
    for (int i = 2; i < argc; i++) {
        AppendQuotedArg(spawnCmd, MAX_COMMAND_LENGTH, argv[i]);
    }

    // Shift held: ask whether to start a separate instance.
    if ((GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0) {
        HANDLE focusThread;
        int choice;

        // Bring the prompt forward even when another window holds the foreground.
        focusThread = CreateThread(NULL, 0, FocusDialogThread,
                                   (LPVOID)(DWORD_PTR)GetCurrentProcessId(), 0, NULL);

        choice = MessageBoxW(
            NULL,
            L"Shift key is held.\n\nOpen in a new Neovide instance?",
            L"Neovide",
            MB_YESNOCANCEL | MB_ICONQUESTION | MB_DEFBUTTON1 | MB_SETFOREGROUND
        );

        if (focusThread) {
            WaitForSingleObject(focusThread, 2000);
            CloseHandle(focusThread);
        }

        if (choice == IDCANCEL) {
            LocalFree(argv);
            return 0;
        }
        if (choice == IDYES) {
            DWORD newPid = RunProcessDetached(spawnCmd);
            FocusNewInstance(newPid);
            LocalFree(argv);
            return 0;
        }
    }

    // Reuse the focused instance if one is alive.
    wchar_t targetPipe[MAX_PATH];
    targetPipe[0] = L'\0';

    if (GetActivePipe(targetPipe, MAX_PATH)) {
        if (!fileArg) {
            FocusInstance(targetPipe);
            LocalFree(argv);
            return 0;
        }

        wchar_t serverCmd[MAX_COMMAND_LENGTH];
        serverCmd[0] = L'\0';
        AppendQuotedArg(serverCmd, MAX_COMMAND_LENGTH, NEOVIM_EXE);
        AppendString(serverCmd, MAX_COMMAND_LENGTH, L" --server");
        AppendQuotedArg(serverCmd, MAX_COMMAND_LENGTH, targetPipe);
        AppendString(serverCmd, MAX_COMMAND_LENGTH, L" --remote-silent");
        AppendQuotedArg(serverCmd, MAX_COMMAND_LENGTH, fileArg);

        if (RunProcessWait(serverCmd) == 0) {
            FocusInstance(targetPipe);
            LocalFree(argv);
            return 0;
        }
    }

    // No live instance: start Neovide.
    RunProcessDetached(spawnCmd);
    LocalFree(argv);
    return 0;
}
