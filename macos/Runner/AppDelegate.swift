import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override init() {
    super.init()
    // Started with `open -n` or as the bare binary (LaunchServices otherwise
    // reuses the running app): bring the running instance forward instead.
    let ownPid = ProcessInfo.processInfo.processIdentifier
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
      .first(where: { $0.processIdentifier != ownPid && !$0.isTerminated }) {
      running.activate(options: [])
      exit(0)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Files opened in Finder arrive here, at launch as well as while running.
  override func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first(where: { $0.isFileURL }),
      let controller = application.windows
        .compactMap({ $0.contentViewController as? FlutterViewController }).first
    else {
      return
    }
    // Waits in the channel buffer until Dart has started up.
    FlutterMethodChannel(name: "app.channel.shared.data", binaryMessenger: controller.engine.binaryMessenger)
      .invokeMethod("openFile", arguments: url.path)
  }
}
