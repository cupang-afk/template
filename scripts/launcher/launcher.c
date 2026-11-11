#define WIN32_LEAN_AND_MEAN
#define _CRT_SECURE_NO_WARNINGS
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <shellapi.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define FALLBACK_PIPE L"\\\\.\\pipe\\neovide"

#ifdef _MSC_VER
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "advapi32.lib")
#endif

static bool ResolveExecutable(const wchar_t *name, wchar_t *outPath, DWORD maxLen) {
    wchar_t exeDir[MAX_PATH];
    if (GetModuleFileNameW(NULL, exeDir, MAX_PATH)) {
        wchar_t *lastSlash = wcsrchr(exeDir, L'\\');
        if (lastSlash) {
            *(lastSlash + 1) = L'\0';
            wchar_t candidate[MAX_PATH];
            _snwprintf(candidate, MAX_PATH, L"%s%s", exeDir, name);
            if (GetFileAttributesW(candidate) != INVALID_FILE_ATTRIBUTES) {
                wcsncpy(outPath, candidate, maxLen);
                return true;
            }
        }
    }

    if (SearchPathW(NULL, name, NULL, maxLen, outPath, NULL) > 0) {
        return true;
    }

    const wchar_t *fallbacks[] = {
        L"F:\\generic\\scoop\\apps\\neovide\\current\\neovide.exe",
        L"F:\\generic\\scoop\\shims\\neovide.exe",
        L"F:\\generic\\scoop\\shims\\nvim.exe"
    };
    for (size_t i = 0; i < sizeof(fallbacks) / sizeof(fallbacks[0]); i++) {
        if (wcsstr(fallbacks[i], name) && GetFileAttributesW(fallbacks[i]) != INVALID_FILE_ATTRIBUTES) {
            wcsncpy(outPath, fallbacks[i], maxLen);
            return true;
        }
    }

    return false;
}

static DWORD RunProcessWait(const wchar_t *cmd, bool hideWindow) {
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    DWORD flags;
    wchar_t cmdBuf[32768];

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));
    flags = hideWindow ? CREATE_NO_WINDOW : 0;

    wcsncpy(cmdBuf, cmd, 32767);
    cmdBuf[32767] = L'\0';

    if (!CreateProcessW(NULL, cmdBuf, NULL, NULL, FALSE, flags, NULL, NULL, &si, &pi)) {
        return (DWORD)-1;
    }

    WaitForSingleObject(pi.hProcess, 4000);
    DWORD exitCode = (DWORD)-1;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return exitCode;
}

static bool RunProcessDetached(const wchar_t *cmd) {
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    wchar_t cmdBuf[32768];

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    wcsncpy(cmdBuf, cmd, 32767);
    cmdBuf[32767] = L'\0';

    if (!CreateProcessW(NULL, cmdBuf, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        return false;
    }
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return true;
}

static bool ProbePipe(const wchar_t *pipeName) {
    if (!pipeName || pipeName[0] == L'\0') {
        return false;
    }
    return WaitNamedPipeW(pipeName, 80) || (GetLastError() == ERROR_PIPE_BUSY);
}

static bool GetActivePipe(wchar_t *outPipe, DWORD maxLen) {
    wchar_t tempPath[MAX_PATH];
    wchar_t activeFilePath[MAX_PATH];

    if (GetTempPathW(MAX_PATH, tempPath) > 0) {
        _snwprintf(activeFilePath, MAX_PATH, L"%sneovide_active.pipe", tempPath);
        HANDLE hFile = CreateFileW(activeFilePath, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        if (hFile != INVALID_HANDLE_VALUE) {
            char buf[512];
            DWORD bytesRead = 0;
            if (ReadFile(hFile, buf, sizeof(buf) - 1, &bytesRead, NULL) && bytesRead > 0) {
                buf[bytesRead] = '\0';
                // Trim trailing whitespace/newlines
                while (bytesRead > 0 && (buf[bytesRead - 1] == '\r' || buf[bytesRead - 1] == '\n' || buf[bytesRead - 1] == ' ')) {
                    buf[--bytesRead] = '\0';
                }
                MultiByteToWideChar(CP_UTF8, 0, buf, -1, outPipe, maxLen);
                CloseHandle(hFile);

                if (ProbePipe(outPipe)) {
                    return true;
                }
            } else {
                CloseHandle(hFile);
            }
        }
    }

    // Fallback: check default pipe
    if (ProbePipe(FALLBACK_PIPE)) {
        wcsncpy(outPipe, FALLBACK_PIPE, maxLen);
        return true;
    }

    return false;
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

    wchar_t neovideExe[MAX_PATH];
    wchar_t nvimExe[MAX_PATH];
    neovideExe[0] = L'\0';
    nvimExe[0] = L'\0';

    if (!ResolveExecutable(L"neovide.exe", neovideExe, MAX_PATH)) {
        MessageBoxW(NULL, L"Could not locate neovide.exe binary.", L"Neovide Launcher", MB_OK | MB_ICONERROR);
        LocalFree(argv);
        return 1;
    }

    // 1. Shift key detection: prompt to spawn independent instance
    SHORT shiftState = GetAsyncKeyState(VK_SHIFT);
    bool isShift = (shiftState & 0x8000) != 0;

    if (isShift) {
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
            wchar_t cmd[32768];
            if (argc > 1) {
                _snwprintf(cmd, 32768, L"\"%s\" \"%s\"", neovideExe, argv[1]);
            } else {
                _snwprintf(cmd, 32768, L"\"%s\"", neovideExe);
            }
            RunProcessDetached(cmd);
            LocalFree(argv);
            return 0;
        }
        // IDNO: Continue to active instance reuse
    }

    // 2. Option 1: Locate active/focused instance pipe
    wchar_t targetPipe[MAX_PATH];
    targetPipe[0] = L'\0';

    if (GetActivePipe(targetPipe, MAX_PATH)) {
        ResolveExecutable(L"nvim.exe", nvimExe, MAX_PATH);

        if (nvimExe[0] != L'\0') {
            if (argc > 1) {
                // Open file in new tab in active instance
                wchar_t remoteCmd[32768];
                _snwprintf(remoteCmd, 32768, L"\"%s\" --server %s --remote-tab-silent \"%s\"", nvimExe, targetPipe, argv[1]);
                DWORD exitCode = RunProcessWait(remoteCmd, true);

                if (exitCode == 0) {
                    wchar_t focusCmd[1024];
                    _snwprintf(focusCmd, 1024, L"\"%s\" --server %s --remote-send \"<Cmd>NeovideFocus<CR>\"", nvimExe, targetPipe);
                    RunProcessWait(focusCmd, true);
                    LocalFree(argv);
                    return 0;
                }
            } else {
                // No file passed: simply bring active window to front
                wchar_t focusCmd[1024];
                _snwprintf(focusCmd, 1024, L"\"%s\" --server %s --remote-send \"<Cmd>NeovideFocus<CR>\"", nvimExe, targetPipe);
                RunProcessWait(focusCmd, true);
                LocalFree(argv);
                return 0;
            }
        }
    }

    // 3. Fallback: No running instance or remote failed -> Launch new Neovide
    wchar_t spawnCmd[32768];
    if (argc > 1) {
        _snwprintf(spawnCmd, 32768, L"\"%s\" \"%s\"", neovideExe, argv[1]);
    } else {
        _snwprintf(spawnCmd, 32768, L"\"%s\"", neovideExe);
    }

    RunProcessDetached(spawnCmd);
    LocalFree(argv);
    return 0;
}
