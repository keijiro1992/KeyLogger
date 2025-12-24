import Foundation
import GRDB

/// データベース管理クラス
actor DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbWriter: DatabaseWriter?
    
    private init() {}
    
    /// データベースのセットアップ
    func setup() throws {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("KeyLogger", isDirectory: true)
        
        try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        let dbPath = appDirectory.appendingPathComponent("keylogger.sqlite").path
        
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }
        
        let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
        self.dbWriter = dbQueue
        
        try migrator.migrate(dbQueue)
        
        print("Database initialized at: \(dbPath)")
    }
    
    /// マイグレーション定義
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            // キーイベントテーブル
            try db.create(table: "key_events") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .datetime).notNull()
                t.column("keyCode", .integer).notNull()
                t.column("keyName", .text).notNull()
                t.column("modifiers", .integer).notNull()
                t.column("isShortcut", .boolean).notNull()
                t.column("appName", .text)
                t.column("appBundleId", .text)
            }
            
            // インデックス
            try db.create(index: "idx_key_events_timestamp", on: "key_events", columns: ["timestamp"])
            try db.create(index: "idx_key_events_appName", on: "key_events", columns: ["appName"])
            
            // 日別統計テーブル
            try db.create(table: "daily_stats") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("date", .date).notNull().unique()
                t.column("totalKeystrokes", .integer).notNull().defaults(to: 0)
                t.column("totalShortcuts", .integer).notNull().defaults(to: 0)
                t.column("mostUsedKey", .text)
                t.column("mostUsedShortcut", .text)
            }
        }
        
        return migrator
    }
    
    /// キーイベントを保存
    func saveEvent(_ event: KeyEvent) async throws {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        try await dbWriter.write { db in
            var event = event
            try event.insert(db)
        }
    }
    
    /// 今日のキーイベント数を取得
    func getTodayKeystrokeCount() async throws -> Int {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return try await dbWriter.read { db in
            try KeyEvent
                .filter(KeyEvent.Columns.timestamp >= today && KeyEvent.Columns.timestamp < tomorrow)
                .fetchCount(db)
        }
    }
    
    /// 今日のショートカット数を取得
    func getTodayShortcutCount() async throws -> Int {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return try await dbWriter.read { db in
            try KeyEvent
                .filter(KeyEvent.Columns.timestamp >= today && KeyEvent.Columns.timestamp < tomorrow)
                .filter(KeyEvent.Columns.isShortcut == true)
                .fetchCount(db)
        }
    }
    
    /// 時間帯別統計を取得
    func getHourlyStats(for date: Date) async throws -> [HourlyStats] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT strftime('%H', timestamp) as hour, COUNT(*) as count
                FROM key_events
                WHERE timestamp >= ? AND timestamp < ?
                GROUP BY strftime('%H', timestamp)
                ORDER BY hour
                """, arguments: [startOfDay, endOfDay])
            
            return rows.map { row in
                HourlyStats(
                    hour: Int(row["hour"] as String) ?? 0,
                    count: row["count"]
                )
            }
        }
    }
    
    /// アプリ別統計を取得
    func getAppStats(for date: Date) async throws -> [AppStats] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT 
                    COALESCE(appName, 'Unknown') as appName,
                    COUNT(*) as keystrokeCount,
                    SUM(CASE WHEN isShortcut = 1 THEN 1 ELSE 0 END) as shortcutCount
                FROM key_events
                WHERE timestamp >= ? AND timestamp < ?
                GROUP BY appName
                ORDER BY keystrokeCount DESC
                """, arguments: [startOfDay, endOfDay])
            
            return rows.map { row in
                AppStats(
                    appName: row["appName"],
                    keystrokeCount: row["keystrokeCount"],
                    shortcutCount: row["shortcutCount"]
                )
            }
        }
    }
    
    /// 最近のイベントを取得
    func getRecentEvents(limit: Int = 100) async throws -> [KeyEvent] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        return try await dbWriter.read { db in
            try KeyEvent
                .order(KeyEvent.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
    
    /// キー使用頻度ランキングを取得（多い順）
    func getKeyFrequency(for date: Date, appName: String? = nil, limit: Int = 15) async throws -> [KeyFrequency] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await dbWriter.read { db in
            let sql: String
            let arguments: StatementArguments
            
            if let appName = appName {
                sql = """
                    SELECT keyName, COUNT(*) as count
                    FROM key_events
                    WHERE timestamp >= ? AND timestamp < ? AND isShortcut = 0 AND appName = ?
                    GROUP BY keyName
                    ORDER BY count DESC
                    LIMIT ?
                    """
                arguments = [startOfDay, endOfDay, appName, limit]
            } else {
                sql = """
                    SELECT keyName, COUNT(*) as count
                    FROM key_events
                    WHERE timestamp >= ? AND timestamp < ? AND isShortcut = 0
                    GROUP BY keyName
                    ORDER BY count DESC
                    LIMIT ?
                    """
                arguments = [startOfDay, endOfDay, limit]
            }
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
            
            return rows.map { row in
                KeyFrequency(
                    keyName: row["keyName"],
                    count: row["count"]
                )
            }
        }
    }
    
    /// ショートカット使用頻度ランキングを取得（多い順）
    func getShortcutFrequency(for date: Date, appName: String? = nil, limit: Int = 15) async throws -> [ShortcutFrequency] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await dbWriter.read { db in
            let sql: String
            let arguments: StatementArguments
            
            if let appName = appName {
                sql = """
                    SELECT keyName, modifiers, COUNT(*) as count
                    FROM key_events
                    WHERE timestamp >= ? AND timestamp < ? AND isShortcut = 1 AND appName = ?
                    GROUP BY keyName, modifiers
                    ORDER BY count DESC
                    LIMIT ?
                    """
                arguments = [startOfDay, endOfDay, appName, limit]
            } else {
                sql = """
                    SELECT keyName, modifiers, COUNT(*) as count
                    FROM key_events
                    WHERE timestamp >= ? AND timestamp < ? AND isShortcut = 1
                    GROUP BY keyName, modifiers
                    ORDER BY count DESC
                    LIMIT ?
                    """
                arguments = [startOfDay, endOfDay, limit]
            }
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
            
            return rows.map { row in
                let modifiers = ModifierFlags(rawValue: row["modifiers"] as Int)
                let keyName: String = row["keyName"]
                let displayName = modifiers.description + keyName
                return ShortcutFrequency(
                    shortcut: displayName,
                    keyName: keyName,
                    modifiers: modifiers.rawValue,
                    count: row["count"]
                )
            }
        }
    }
    
    /// 今日使用したアプリ一覧を取得
    func getUsedApps(for date: Date) async throws -> [String] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT DISTINCT COALESCE(appName, 'Unknown') as appName
                FROM key_events
                WHERE timestamp >= ? AND timestamp < ?
                ORDER BY appName
                """, arguments: [startOfDay, endOfDay])
            
            return rows.map { $0["appName"] as String }
        }
    }
    
    /// キー頻度マップを取得（ヒートマップ用）
    func getKeyFrequencyMap(for date: Date) async throws -> [String: Int] {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT keyName, COUNT(*) as count
                FROM key_events
                WHERE timestamp >= ? AND timestamp < ?
                GROUP BY keyName
                """, arguments: [startOfDay, endOfDay])
            
            var result: [String: Int] = [:]
            for row in rows {
                let keyName: String = row["keyName"]
                let count: Int = row["count"]
                result[keyName] = count
            }
            return result
        }
    }
    
    /// 古いイベントを削除（保持期間: 7日）
    func cleanupOldEvents() async throws {
        guard let dbWriter = dbWriter else {
            throw DatabaseError.notInitialized
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        try await dbWriter.write { db in
            try db.execute(sql: "DELETE FROM key_events WHERE timestamp < ?", arguments: [cutoffDate])
        }
        
        print("Cleaned up events older than 7 days")
    }
}

/// データベースエラー
enum DatabaseError: Error {
    case notInitialized
    case queryFailed(String)
}
