#define WIN32_LEAN_AND_MEAN
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <shellapi.h>
#include <wchar.h>

#define ACTIVE_PIPE_FILE L"neovide_active.pipe"
#define FALLBACK_PIPE L"\\\\.\\pipe\\neovide"
#define NEOVIM_EXE L"nvim.exe"
#define MAX_COMMAND_LENGTH 32768

#ifdef _MSC_VER
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "shell32.lib")
#endif

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

static void RunProcessDetached(const wchar_t *cmd) {
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    wchar_t cmdBuf[MAX_COMMAND_LENGTH];

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    lstrcpynW(cmdBuf, cmd, MAX_COMMAND_LENGTH);

    if (CreateProcessW(NULL, cmdBuf, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    }
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

                outPipe[0] = L'\0';
                if (MultiByteToWideChar(CP_UTF8, 0, buf, -1, outPipe, (int)maxLen) > 0 && ProbePipe(outPipe)) {
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

static void FocusInstance(const wchar_t *pipeName) {
    WindowSearch search;
    DWORD foregroundThread;
    DWORD currentThread;
    BOOL attached = FALSE;

    search.pid = PipePid(pipeName);
    search.window = NULL;
    if (search.pid == 0) {
        return;
    }

    EnumWindows(FindProcessWindow, (LPARAM)&search);
    if (!search.window) {
        return;
    }

    if (IsIconic(search.window)) {
        ShowWindow(search.window, SW_RESTORE);
    }

    foregroundThread = GetWindowThreadProcessId(GetForegroundWindow(), NULL);
    currentThread = GetCurrentThreadId();
    if (foregroundThread != 0 && foregroundThread != currentThread) {
        attached = AttachThreadInput(currentThread, foregroundThread, TRUE);
    }

    SetForegroundWindow(search.window);

    if (attached) {
        AttachThreadInput(currentThread, foregroundThread, FALSE);
    }
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd) {
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nShowCmd;

    int argc = 0;
    LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
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
        int choice = MessageBoxW(
            NULL,
            L"Shift key is held.\n\nOpen in a new Neovide instance?",
            L"Neovide",
            MB_YESNOCANCEL | MB_ICONQUESTION | MB_DEFBUTTON1
        );
        if (choice == IDCANCEL) {
            LocalFree(argv);
            return 0;
        }
        if (choice == IDYES) {
            RunProcessDetached(spawnCmd);
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
