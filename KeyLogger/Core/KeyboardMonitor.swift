import Foundation
import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// キーボード監視クラス
@MainActor
class KeyboardMonitor: ObservableObject {
    static let shared = KeyboardMonitor()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    @Published var isMonitoring = false
    @Published var isPaused = false
    @Published var todayKeystrokes = 0
    @Published var todayShortcuts = 0
    
    /// 除外するアプリのバンドルID
    private let excludedBundleIds: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.lastpass.LastPass",
        "com.bitwarden.desktop",
        "com.apple.keychainaccess",
    ]
    
    private init() {}
    
    /// 監視を開始
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // アクセシビリティ権限のチェック
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        guard accessEnabled else {
            print("Accessibility permission not granted")
            return
        }
        
        // CGEventTapの作成
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // コールバック関数を定義
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
            
            Task { @MainActor in
                await monitor.handleEvent(event)
            }
            
            return Unmanaged.passRetained(event)
        }
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.runLoopSource = runLoopSource
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isMonitoring = true
        print("Keyboard monitoring started")
        
        // 初期統計を取得
        Task {
            await refreshStats()
        }
    }
    
    /// 監視を停止
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        print("Keyboard monitoring stopped")
    }
    
    /// 一時停止/再開
    func togglePause() {
        isPaused.toggle()
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: !isPaused)
        }
    }
    
    /// イベントを処理
    private func handleEvent(_ event: CGEvent) async {
        guard !isPaused else { return }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 修飾キーのみの場合はスキップ
        if KeyCodeMapper.isModifierKey(keyCode) {
            return
        }
        
        // アクティブなアプリケーション情報を取得
        let (appName, bundleId) = getActiveApplication()
        
        // 除外アプリのチェック
        if let bundleId = bundleId, excludedBundleIds.contains(bundleId) {
            return
        }
        
        // パスワードフィールドのチェック（セキュアテキスト入力をスキップ）
        if isSecureInputEnabled() {
            return
        }
        
        // 修飾キーの取得
        let flags = event.flags
        var modifiers = ModifierFlags()
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskSecondaryFn) { modifiers.insert(.function) }
        
        let keyName = KeyCodeMapper.keyName(for: keyCode)
        let isShortcut = modifiers.isShortcut
        
        let keyEvent = KeyEvent(
            id: nil,
            timestamp: Date(),
            keyCode: keyCode,
            keyName: keyName,
            modifiers: modifiers.rawValue,
            isShortcut: isShortcut,
            appName: appName,
            appBundleId: bundleId
        )
        
        // データベースに保存
        do {
            try await DatabaseManager.shared.saveEvent(keyEvent)
            
            // 統計を更新
            todayKeystrokes += 1
            if isShortcut {
                todayShortcuts += 1
            }
        } catch {
            print("Failed to save event: \(error)")
        }
    }
    
    /// アクティブなアプリケーション情報を取得
    private func getActiveApplication() -> (name: String?, bundleId: String?) {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return (nil, nil)
        }
        return (app.localizedName, app.bundleIdentifier)
    }
    
    /// セキュア入力（パスワードフィールド）が有効かどうかを確認
    private func isSecureInputEnabled() -> Bool {
        return SecureInput.isEnabled()
    }
    
    /// 統計を更新
    func refreshStats() async {
        do {
            todayKeystrokes = try await DatabaseManager.shared.getTodayKeystrokeCount()
            todayShortcuts = try await DatabaseManager.shared.getTodayShortcutCount()
        } catch {
            print("Failed to refresh stats: \(error)")
        }
    }
}

/// セキュア入力のチェック
struct SecureInput {
    static func isEnabled() -> Bool {
        // IsSecureEventInputEnabled()はセキュアテキストフィールドへの入力中にtrueを返す
        return IsSecureEventInputEnabled()
    }
}
