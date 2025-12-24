import SwiftUI
import Charts

/// ログビューア
struct LogViewerView: View {
    @State private var recentEvents: [KeyEvent] = []
    @State private var hourlyStats: [HourlyStats] = []
    @State private var appStats: [AppStats] = []
    @State private var keyFrequency: [KeyFrequency] = []
    @State private var shortcutFrequency: [ShortcutFrequency] = []
    @State private var keyFrequencyMap: [String: Int] = [:]
    @State private var usedApps: [String] = []
    @State private var selectedApp: String = "すべて"
    @State private var selectedTab = 0
    @State private var isLoading = true
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ヒートマップタブ
            heatmapView
                .tabItem {
                    Label("ヒートマップ", systemImage: "keyboard")
                }
                .tag(0)
            
            // キー使用頻度タブ
            keyFrequencyView
                .tabItem {
                    Label("キー頻度", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // ショートカット頻度タブ
            shortcutFrequencyView
                .tabItem {
                    Label("ショートカット", systemImage: "command")
                }
                .tag(2)
            
            // 時間帯別統計タブ
            hourlyStatsView
                .tabItem {
                    Label("時間帯別", systemImage: "clock")
                }
                .tag(3)
            
            // アプリ別統計タブ
            appStatsView
                .tabItem {
                    Label("アプリ別", systemImage: "app.badge")
                }
                .tag(4)
            
            // 最近のログタブ
            recentLogsView
                .tabItem {
                    Label("ログ", systemImage: "list.bullet")
                }
                .tag(5)
        }
        .frame(minWidth: 750, minHeight: 550)
        .task {
            await loadData()
        }
    }
    
    /// ヒートマップビュー
    private var heatmapView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("キーボードヒートマップ")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("今日使用したキーの頻度を色で表示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { Task { await loadData() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if keyFrequencyMap.isEmpty {
                emptyStateView(icon: "keyboard", message: "キー入力データがありません")
            } else {
                VStack(spacing: 16) {
                    KeyboardHeatmapView(
                        keyFrequency: keyFrequencyMap,
                        maxCount: keyFrequencyMap.values.max() ?? 1
                    )
                    
                    HeatmapLegend()
                    
                    // 統計サマリー
                    HStack(spacing: 24) {
                        VStack {
                            Text("\(keyFrequencyMap.values.reduce(0, +))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("総キー入力")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(keyFrequencyMap.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("使用キー種類")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let maxKey = keyFrequencyMap.max(by: { $0.value < $1.value }) {
                            VStack {
                                Text(maxKey.key)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("最多キー (\(maxKey.value)回)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    /// アプリ選択ドロップダウン
    private var appPicker: some View {
        Picker("アプリ", selection: $selectedApp) {
            Text("すべて").tag("すべて")
            Divider()
            ForEach(usedApps, id: \.self) { app in
                Text(app).tag(app)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 200)
        .onChange(of: selectedApp) { _ in
            Task { await loadFilteredData() }
        }
    }
    
    /// キー使用頻度ビュー（多い順棒グラフ）
    private var keyFrequencyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("キー使用頻度ランキング")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("最も多く使ったキー（ショートカット除く）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                appPicker
                
                Button(action: { Task { await loadData() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if keyFrequency.isEmpty {
                emptyStateView(icon: "keyboard", message: "キー入力データがありません")
            } else {
                Chart(keyFrequency) { item in
                    BarMark(
                        x: .value("回数", item.count),
                        y: .value("キー", item.keyName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let keyName = value.as(String.self) {
                                Text(keyName)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    /// ショートカット使用頻度ビュー
    private var shortcutFrequencyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("ショートカット使用頻度")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("最も多く使ったショートカット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                appPicker
                
                Button(action: { Task { await loadData() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if shortcutFrequency.isEmpty {
                emptyStateView(icon: "command", message: "ショートカットデータがありません")
            } else {
                Chart(shortcutFrequency) { item in
                    BarMark(
                        x: .value("回数", item.count),
                        y: .value("ショートカット", item.shortcut)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let shortcut = value.as(String.self) {
                                Text(shortcut)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    /// 時間帯別統計ビュー
    private var hourlyStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("時間帯別キー入力数")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("1時間ごとのキー入力回数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hourlyStats.isEmpty {
                emptyStateView(icon: "chart.bar", message: "今日のキー入力データがありません")
            } else {
                Chart(hourlyStats, id: \.hour) { stat in
                    BarMark(
                        x: .value("時間", "\(stat.hour)"),
                        y: .value("回数", stat.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxisLabel("時間帯")
                .chartYAxisLabel("キー入力数")
                .padding()
            }
            
            Spacer()
        }
    }
    
    /// アプリ別統計ビュー
    private var appStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("アプリ別統計")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("各アプリでのキー入力とショートカット使用回数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appStats.isEmpty {
                emptyStateView(icon: "app.badge", message: "今日のアプリ別データがありません")
            } else {
                // 横棒グラフで多い順表示
                Chart(appStats, id: \.appName) { stat in
                    BarMark(
                        x: .value("入力数", stat.keystrokeCount),
                        y: .value("アプリ", stat.appName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        HStack(spacing: 4) {
                            Text("\(stat.keystrokeCount)")
                                .font(.caption)
                            if stat.shortcutCount > 0 {
                                Text("(⌘\(stat.shortcutCount))")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let appName = value.as(String.self) {
                                Text(appName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    /// 最近のログビュー
    private var recentLogsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("最近のキー入力")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("直近100件のキー入力履歴")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { Task { await loadData() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if recentEvents.isEmpty {
                emptyStateView(icon: "keyboard", message: "キー入力ログがまだありません")
            } else {
                Table(recentEvents) {
                    TableColumn("時刻") { event in
                        Text(formatTime(event.timestamp))
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(80)
                    
                    TableColumn("キー") { event in
                        Text(event.displayString)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                event.isShortcut
                                    ? LinearGradient(colors: [.purple.opacity(0.2), .pink.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(6)
                    }
                    .width(min: 100, ideal: 140)
                    
                    TableColumn("アプリ") { event in
                        Text(event.appName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    TableColumn("タイプ") { event in
                        if event.isShortcut {
                            Label("ショートカット", systemImage: "command")
                                .font(.caption)
                                .foregroundColor(.purple)
                        } else {
                            Label("通常", systemImage: "character.cursor.ibeam")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .width(120)
                }
            }
            
            Spacer()
        }
    }
    
    /// 空状態ビュー
    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// すべてのデータをロード
    private func loadData() async {
        isLoading = true
        
        do {
            usedApps = try await DatabaseManager.shared.getUsedApps(for: Date())
            recentEvents = try await DatabaseManager.shared.getRecentEvents(limit: 100)
            hourlyStats = try await DatabaseManager.shared.getHourlyStats(for: Date())
            appStats = try await DatabaseManager.shared.getAppStats(for: Date())
            keyFrequencyMap = try await DatabaseManager.shared.getKeyFrequencyMap(for: Date())
            
            let appFilter = selectedApp == "すべて" ? nil : selectedApp
            keyFrequency = try await DatabaseManager.shared.getKeyFrequency(for: Date(), appName: appFilter, limit: 15)
            shortcutFrequency = try await DatabaseManager.shared.getShortcutFrequency(for: Date(), appName: appFilter, limit: 15)
        } catch {
            print("Failed to load data: \(error)")
        }
        
        isLoading = false
    }
    
    /// フィルター変更時にデータをリロード
    private func loadFilteredData() async {
        do {
            let appFilter = selectedApp == "すべて" ? nil : selectedApp
            keyFrequency = try await DatabaseManager.shared.getKeyFrequency(for: Date(), appName: appFilter, limit: 15)
            shortcutFrequency = try await DatabaseManager.shared.getShortcutFrequency(for: Date(), appName: appFilter, limit: 15)
        } catch {
            print("Failed to load filtered data: \(error)")
        }
    }
    
    /// 時刻をフォーマット
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
