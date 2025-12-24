import SwiftUI
import AppKit

/// アプリケーションデリゲート
class AppDelegate: NSObject, NSApplicationDelegate {
    @Published var showLogViewer = false
    @Published var showSettings = false
    
    private var logViewerWindow: NSWindow?
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
        
        // データベースの初期化
        Task {
            do {
                try await DatabaseManager.shared.setup()
                
                // 古いイベントのクリーンアップ
                try await DatabaseManager.shared.cleanupOldEvents()
                
                // キーボード監視の開始
                await MainActor.run {
                    if PermissionManager.isAccessibilityGranted() {
                        KeyboardMonitor.shared.startMonitoring()
                    } else {
                        // 権限がない場合は設定を表示
                        showPermissionAlert()
                    }
                }
            } catch {
                print("Failed to initialize: \(error)")
            }
        }
        
        // 定期的な統計更新
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await KeyboardMonitor.shared.refreshStats()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        KeyboardMonitor.shared.stopMonitoring()
    }
    
    /// 権限要求アラートを表示
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ権限が必要です"
            alert.informativeText = "キーボード入力を記録するには、アクセシビリティ権限が必要です。「システム設定」を開いて権限を許可してください。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "システム設定を開く")
            alert.addButton(withTitle: "後で")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                PermissionManager.openAccessibilityPreferences()
            }
        }
    }
    
    /// ログビューアウィンドウを表示
    func openLogViewer() {
        if let window = logViewerWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let logViewerView = LogViewerView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "キー入力ログ"
        window.contentView = NSHostingView(rootView: logViewerView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        logViewerWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 設定ウィンドウを表示
    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
