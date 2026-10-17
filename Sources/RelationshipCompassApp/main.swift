@testable import RelationshipCompass
import SwiftUI
import AppKit

/// 命令行方式运行时，确保窗口激活到前台并显示 Dock 图标
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct RelationshipCompassApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: ContactStore

    init() {
        _store = StateObject(wrappedValue: ContactStore())
    }

    var body: some Scene {
        WindowGroup("人脉罗盘") {
            ContentView()
                .environmentObject(store)
        }
    }
}
