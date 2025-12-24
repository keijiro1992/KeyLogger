import Foundation
import ServiceManagement

/// ログイン時自動起動を管理するマネージャー
struct LoginItemManager {
    
    /// 現在のログイン項目の状態を取得
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS (not expected to be used)
            return false
        }
    }
    
    /// ログイン時自動起動を有効/無効にする
    /// - Parameter enabled: 有効にする場合は true
    /// - Returns: 成功した場合は true
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ ログイン項目に登録しました")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("✅ ログイン項目から削除しました")
                }
                return true
            } catch {
                print("❌ ログイン項目の更新に失敗: \(error.localizedDescription)")
                return false
            }
        }
        return false
    }
    
    /// 現在の状態を文字列で取得
    static var statusDescription: String {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                return "有効"
            case .notRegistered:
                return "未登録"
            case .notFound:
                return "見つかりません"
            case .requiresApproval:
                return "承認が必要"
            @unknown default:
                return "不明"
            }
        }
        return "非対応"
    }
}
