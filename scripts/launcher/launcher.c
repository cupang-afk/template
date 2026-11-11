#define WIN32_LEAN_AND_MEAN
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

#define NEOVIDE_PIPE L"\\\\.\\pipe\\neovide"

static bool ResolveExecutable(const wchar_t *name, wchar_t *outPath, DWORD maxLen) {
    // 1. Same directory as launcher
    wchar_t exeDir[MAX_PATH];
    if (GetModuleFileNameW(NULL, exeDir, MAX_PATH)) {
        wchar_t *lastSlash = wcsrchr(exeDir, L'\\');
        if (lastSlash) {
            *(lastSlash + 1) = L'\0';
            wchar_t candidate[MAX_PATH];
            swprintf_s(candidate, MAX_PATH, L"%s%s", exeDir, name);
            if (GetFileAttributesW(candidate) != INVALID_FILE_ATTRIBUTES) {
                wcsncpy_s(outPath, maxLen, candidate, _TRUNCATE);
                return true;
            }
        }
    }

    // 2. Windows PATH lookup
    if (SearchPathW(NULL, name, NULL, maxLen, outPath, NULL) > 0) {
        return true;
    }

    // 3. Known Scoop & standard locations fallback
    const wchar_t *fallbacks[] = {
        L"F:\\generic\\scoop\\apps\\neovide\\current\\neovide.exe",
        L"F:\\generic\\scoop\\shims\\neovide.exe",
        L"F:\\generic\\scoop\\shims\\nvim.exe"
    };
    for (size_t i = 0; i < sizeof(fallbacks) / sizeof(fallbacks[0]); i++) {
        if (wcsstr(fallbacks[i], name) && GetFileAttributesW(fallbacks[i]) != INVALID_FILE_ATTRIBUTES) {
            wcsncpy_s(outPath, maxLen, fallbacks[i], _TRUNCATE);
            return true;
        }
    }

    return false;
}

static DWORD RunProcessWait(const wchar_t *cmd, bool hideWindow) {
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };
    DWORD flags = hideWindow ? CREATE_NO_WINDOW : 0;

    wchar_t cmdBuf[32768];
    wcsncpy_s(cmdBuf, 32768, cmd, _TRUNCATE);

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
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };

    wchar_t cmdBuf[32768];
    wcsncpy_s(cmdBuf, 32768, cmd, _TRUNCATE);

    if (!CreateProcessW(NULL, cmdBuf, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        return false;
    }
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return true;
}

static bool IsPipeAvailable(void) {
    return WaitNamedPipeW(NEOVIDE_PIPE, 100) || (GetLastError() == ERROR_PIPE_BUSY);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nShowCmd) {
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nShowCmd;

    int argc = 0;
    LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argv) {
        return 1;
    }

    wchar_t neovideExe[MAX_PATH] = { 0 };
    wchar_t nvimExe[MAX_PATH] = { 0 };

    if (!ResolveExecutable(L"neovide.exe", neovideExe, MAX_PATH)) {
        MessageBoxW(NULL, L"Could not locate neovide.exe binary.", L"Neovide Launcher", MB_OK | MB_ICONERROR);
        LocalFree(argv);
        return 1;
    }

    // 1. Shift key detection
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
            // Spawn new isolated Neovide instance
            wchar_t cmd[32768];
            if (argc > 1) {
                swprintf_s(cmd, 32768, L"\"%s\" \"%s\"", neovideExe, argv[1]);
            } else {
                swprintf_s(cmd, 32768, L"\"%s\"", neovideExe);
            }
            RunProcessDetached(cmd);
            LocalFree(argv);
            return 0;
        }
        // IDNO: fall through to existing instance reuse
    }

    // 2. Normal flow: Check if pipe is active
    if (IsPipeAvailable()) {
        ResolveExecutable(L"nvim.exe", nvimExe, MAX_PATH);

        if (nvimExe[0] != L'\0') {
            if (argc > 1) {
                // Open file in new tab of running instance
                wchar_t remoteCmd[32768];
                swprintf_s(remoteCmd, 32768, L"\"%s\" --server %s --remote-tab-silent \"%s\"", nvimExe, NEOVIDE_PIPE, argv[1]);
                DWORD exitCode = RunProcessWait(remoteCmd, true);

                if (exitCode == 0) {
                    // Focus window
                    wchar_t focusCmd[1024];
                    swprintf_s(focusCmd, 1024, L"\"%s\" --server %s --remote-send \"<Cmd>NeovideFocus<CR>\"", nvimExe, NEOVIDE_PIPE);
                    RunProcessWait(focusCmd, true);
                    LocalFree(argv);
                    return 0;
                }
            } else {
                // No file passed: simply focus running window
                wchar_t focusCmd[1024];
                swprintf_s(focusCmd, 1024, L"\"%s\" --server %s --remote-send \"<Cmd>NeovideFocus<CR>\"", nvimExe, NEOVIDE_PIPE);
                RunProcessWait(focusCmd, true);
                LocalFree(argv);
                return 0;
            }
        }
    }

    // 3. Fallback: No running instance or remote failed -> Launch new Neovide
    wchar_t spawnCmd[32768];
    if (argc > 1) {
        swprintf_s(spawnCmd, 32768, L"\"%s\" \"%s\"", neovideExe, argv[1]);
    } else {
        swprintf_s(spawnCmd, 32768, L"\"%s\"", neovideExe);
    }

    RunProcessDetached(spawnCmd);
    LocalFree(argv);
    return 0;
}
