import SwiftUI

/// アプリ状態管理
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    @Published var showLogViewer = false
    @Published var showSettings = false
}

/// メインアプリケーション
@main
struct KeyLoggerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var monitor = KeyboardMonitor.shared
    
    var body: some Scene {
        // メニューバーアプリとして動作
        MenuBarExtra {
            MenuBarView(
                monitor: monitor,
                showLogViewer: $appState.showLogViewer,
                showSettings: $appState.showSettings
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                Text("\(monitor.todayKeystrokes)")
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
        
        // ログビューアウィンドウ
        Window("キー入力ログ", id: "log-viewer") {
            LogViewerView()
        }
        .windowResizability(.contentSize)
        
        // 設定ウィンドウ
        Window("設定", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}
