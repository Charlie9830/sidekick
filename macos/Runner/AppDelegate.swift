import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  // Route Quit (⌘Q) through the window-close path so window_manager's
  // preventClose hook can intercept it and show the unsaved-changes prompt
  // before the app terminates. See design_docs/window-management-spec.md §4b.
  // The release preflight (scripts/release/build_macos.dart) greps for this
  // override, so a `flutter create` that clobbers this file fails the build.
  override func applicationShouldTerminate(
    _ sender: NSApplication
  ) -> NSApplication.TerminateReply {
    mainFlutterWindow?.performClose(nil)
    return .terminateCancel
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
