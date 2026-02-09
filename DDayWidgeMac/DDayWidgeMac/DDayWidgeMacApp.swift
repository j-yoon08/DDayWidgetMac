import SwiftUI
import AppKit

@main
struct DDayWidgeMacApp: App {
    @StateObject private var store = CalendarStore()

    var body: some Scene {
        WindowGroup {
            DDayView()
                .environmentObject(store)
                .onAppear {
                    store.requestAccessIfNeeded()
                    store.loadMonthEvents()
                    WindowConfigurator.configureMainWindow()
                }
        }
        .defaultSize(width: 860, height: 620)
    }
}

enum WindowConfigurator {
    static func configureMainWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first else { return }
            window.title = "D-DAY 설정/미리보기"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.level = .normal
            window.collectionBehavior = [.moveToActiveSpace]
            window.minSize = NSSize(width: 700, height: 520)
        }
    }
}
