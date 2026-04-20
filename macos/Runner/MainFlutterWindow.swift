import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let size = NSSize(width: 320, height: 380)
    self.setContentSize(size)
    self.minSize = NSSize(width: 320, height: 380)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    FocusTrackerPlugin.register(
      with: flutterViewController.registrar(forPlugin: "FocusTrackerPlugin")
    )

    super.awakeFromNib()
  }
}
