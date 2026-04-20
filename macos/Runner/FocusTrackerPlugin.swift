import Cocoa
import FlutterMacOS

public class FocusTrackerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "activity_tracker/focus",
      binaryMessenger: registrar.messenger
    )
    let instance = FocusTrackerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openSystemSettings":
      let args = call.arguments as? [String: Any] ?? [:]
      let pane = args["pane"] as? String ?? ""
      openSystemSettings(pane: pane)
      result(nil)
    case "checkAccessibility":
      // Using the *WithOptions variant with prompt=false forces macOS to
      // re-read the TCC state rather than returning the process-cached value
      // from the first AXIsProcessTrusted() call.
      let opts: NSDictionary = [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false,
      ]
      result(AXIsProcessTrustedWithOptions(opts))
    case "requestAccessibility":
      let opts: NSDictionary = [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
      ]
      _ = AXIsProcessTrustedWithOptions(opts)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openSystemSettings(pane: String) {
    let urlString: String?
    switch pane {
    case "automation":
      urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
    case "accessibility":
      urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    default:
      urlString = nil
    }
    guard let urlString, let url = URL(string: urlString) else { return }
    NSWorkspace.shared.open(url)
  }
}
