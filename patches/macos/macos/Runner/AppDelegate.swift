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
  // This file is patch-managed: the copy of record lives in
  // patches/macos/macos/Runner/AppDelegate.swift and is restored on every
  // release build, so regenerating macos/ cannot drop this override. Edit
  // both copies together — see patches/README.md.
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
