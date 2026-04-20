#include "focus_tracker_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <psapi.h>
#include <oleauto.h>
#include <uiautomation.h>

#include <memory>
#include <string>

namespace {

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.data(),
                                 static_cast<int>(wide.size()), nullptr, 0,
                                 nullptr, nullptr);
  std::string out(size, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                      out.data(), size, nullptr, nullptr);
  return out;
}

std::wstring WindowTitle(HWND hwnd) {
  int length = GetWindowTextLengthW(hwnd);
  if (length <= 0) return L"";
  std::wstring buffer(length + 1, L'\0');
  int actual = GetWindowTextW(hwnd, buffer.data(), length + 1);
  buffer.resize(actual);
  return buffer;
}

std::wstring ProcessExeName(HWND hwnd) {
  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (pid == 0) return L"";
  HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (!process) return L"";
  wchar_t path[MAX_PATH] = {0};
  DWORD size = MAX_PATH;
  std::wstring result;
  if (QueryFullProcessImageNameW(process, 0, path, &size)) {
    std::wstring full(path, size);
    size_t slash = full.find_last_of(L"\\/");
    std::wstring filename = (slash == std::wstring::npos) ? full : full.substr(slash + 1);
    size_t dot = filename.find_last_of(L'.');
    result = (dot == std::wstring::npos) ? filename : filename.substr(0, dot);
  }
  CloseHandle(process);
  return result;
}

bool IsBrowserExe(const std::wstring& exe) {
  static const wchar_t* kBrowsers[] = {L"chrome", L"msedge", L"brave", L"vivaldi", L"opera"};
  for (auto* b : kBrowsers) {
    if (_wcsicmp(exe.c_str(), b) == 0) return true;
  }
  return false;
}

std::wstring BrowserUrl(HWND hwnd) {
  HRESULT init = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  bool needs_uninit = SUCCEEDED(init);
  std::wstring url;

  IUIAutomation* automation = nullptr;
  HRESULT hr = CoCreateInstance(__uuidof(CUIAutomation), nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&automation));
  if (SUCCEEDED(hr) && automation) {
    IUIAutomationElement* root = nullptr;
    if (SUCCEEDED(automation->ElementFromHandle(hwnd, &root)) && root) {
      IUIAutomationCondition* cond = nullptr;
      VARIANT v;
      VariantInit(&v);
      v.vt = VT_I4;
      v.lVal = UIA_EditControlTypeId;
      if (SUCCEEDED(automation->CreatePropertyCondition(UIA_ControlTypePropertyId, v, &cond)) && cond) {
        IUIAutomationElement* edit = nullptr;
        if (SUCCEEDED(root->FindFirst(TreeScope_Descendants, cond, &edit)) && edit) {
          VARIANT value;
          VariantInit(&value);
          if (SUCCEEDED(edit->GetCurrentPropertyValue(UIA_ValueValuePropertyId, &value)) &&
              value.vt == VT_BSTR && value.bstrVal) {
            url = value.bstrVal;
          }
          VariantClear(&value);
          edit->Release();
        }
        cond->Release();
      }
      VariantClear(&v);
      root->Release();
    }
    automation->Release();
  }

  if (needs_uninit) CoUninitialize();
  return url;
}

void Register(flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "activity_tracker/focus",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "getFocus") {
          result->NotImplemented();
          return;
        }
        HWND hwnd = GetForegroundWindow();
        if (!hwnd) {
          result->Success();
          return;
        }
        std::wstring title = WindowTitle(hwnd);
        std::wstring exe = ProcessExeName(hwnd);
        std::wstring url;
        if (IsBrowserExe(exe)) {
          url = BrowserUrl(hwnd);
        }

        flutter::EncodableMap payload;
        payload[flutter::EncodableValue("app")] = flutter::EncodableValue(WideToUtf8(exe));
        payload[flutter::EncodableValue("title")] = flutter::EncodableValue(WideToUtf8(title));
        if (!url.empty()) {
          payload[flutter::EncodableValue("url")] = flutter::EncodableValue(WideToUtf8(url));
        }
        result->Success(flutter::EncodableValue(payload));
      });

  // Keep the channel alive for the lifetime of the process (this runner-local
  // plugin is registered once at startup and never re-registered).
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> kChannel;
  kChannel = std::move(channel);
  (void)registrar;
}

}  // namespace

extern "C" void FocusTrackerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  Register(flutter::PluginRegistrarManager::GetInstance()
               ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
