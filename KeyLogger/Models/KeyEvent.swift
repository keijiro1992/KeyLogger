import Foundation
import GRDB

/// 修飾キーフラグ
struct ModifierFlags: OptionSet, Codable, Sendable {
    let rawValue: Int
    
    static let command = ModifierFlags(rawValue: 1 << 0)
    static let control = ModifierFlags(rawValue: 1 << 1)
    static let option = ModifierFlags(rawValue: 1 << 2)
    static let shift = ModifierFlags(rawValue: 1 << 3)
    static let function = ModifierFlags(rawValue: 1 << 4)
    
    /// 修飾キーの文字列表現を取得
    var description: String {
        var parts: [String] = []
        if contains(.control) { parts.append("⌃") }
        if contains(.option) { parts.append("⌥") }
        if contains(.shift) { parts.append("⇧") }
        if contains(.command) { parts.append("⌘") }
        if contains(.function) { parts.append("fn") }
        return parts.joined()
    }
    
    /// ショートカットかどうか（Command, Control, Optionのいずれかを含む）
    var isShortcut: Bool {
        return contains(.command) || contains(.control) || contains(.option)
    }
}

/// キーイベントモデル
struct KeyEvent: Codable, Identifiable, FetchableRecord, PersistableRecord, Sendable {
    var id: Int64?
    let timestamp: Date
    let keyCode: Int
    let keyName: String
    let modifiers: Int
    let isShortcut: Bool
    let appName: String?
    let appBundleId: String?
    
    static let databaseTableName = "key_events"
    
    /// 修飾キーフラグを取得
    var modifierFlags: ModifierFlags {
        return ModifierFlags(rawValue: modifiers)
    }
    
    /// 表示用のキー文字列
    var displayString: String {
        let modStr = modifierFlags.description
        if modStr.isEmpty {
            return keyName
        }
        return "\(modStr)\(keyName)"
    }
    
    // MARK: - FetchableRecord
    
    enum Columns: String, ColumnExpression {
        case id, timestamp, keyCode, keyName, modifiers, isShortcut, appName, appBundleId
    }
    
    // MARK: - PersistableRecord
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

/// 日別統計モデル
struct DailyStats: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    var id: Int64?
    let date: Date
    var totalKeystrokes: Int
    var totalShortcuts: Int
    var mostUsedKey: String?
    var mostUsedShortcut: String?
    
    static let databaseTableName = "daily_stats"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

/// 時間帯別統計
struct HourlyStats: Codable, Sendable {
    let hour: Int
    let count: Int
}

/// アプリ別統計
struct AppStats: Codable, Sendable {
    let appName: String
    let keystrokeCount: Int
    let shortcutCount: Int
}

/// キー使用頻度
struct KeyFrequency: Codable, Sendable, Identifiable {
    var id: String { keyName }
    let keyName: String
    let count: Int
}

/// ショートカット使用頻度
struct ShortcutFrequency: Codable, Sendable, Identifiable {
    var id: String { shortcut }
    let shortcut: String
    let keyName: String
    let modifiers: Int
    let count: Int
}
