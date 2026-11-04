#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Also named in release_tools/windows_installer_build.iss (AppMutex).
constexpr wchar_t kSingleInstanceMutexName[] = L"Local\\de.krush62.kpix";

// Hands the file of this launch, if any, to the running instance's |window|.
void ForwardFile(HWND window) {
  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return;
  }
  // Absolute, as the running instance has a working directory of its own.
  const DWORD length =
      argc > 1 ? ::GetFullPathNameW(argv[1], 0, nullptr, nullptr) : 0;
  std::wstring path(length, L'\0');
  if (length > 0) {
    path.resize(::GetFullPathNameW(argv[1], length, path.data(), nullptr));
  }
  ::LocalFree(argv);
  if (path.empty()) {
    return;
  }
  COPYDATASTRUCT data{FlutterWindow::kOpenFileCopyDataId,
                      static_cast<DWORD>(path.size() * sizeof(wchar_t)),
                      path.data()};
  ::SendMessageTimeoutW(window, WM_COPYDATA, 0,
                        reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG,
                        5000, nullptr);
}

// Brings the already running instance to the front and hands it this launch's
// file.
void ActivateRunningInstance() {
  HWND window = ::FindWindowW(Win32Window::kWindowClassName, nullptr);
  if (window == nullptr) {
    return;
  }
  // Still hidden while that instance starts up; it shows itself when ready.
  if (::IsWindowVisible(window)) {
    if (::IsIconic(window)) {
      ::ShowWindow(window, SW_RESTORE);
    }
    ::SetForegroundWindow(::GetLastActivePopup(window));
  }
  ForwardFile(window);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Never closed: Windows releases it when the process ends, crashes included.
  ::CreateMutexW(nullptr, FALSE, kSingleInstanceMutexName);
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ActivateRunningInstance();
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"kpix", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
