import Foundation
import AppKit
import ApplicationServices

/// 権限管理クラス
struct PermissionManager {
    
    /// アクセシビリティ権限が付与されているかチェック
    static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// アクセシビリティ権限を要求
    static func requestAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// システム環境設定のアクセシビリティ設定を開く
    static func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
