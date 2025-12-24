import SwiftUI

/// メニューバービュー
struct MenuBarView: View {
    @ObservedObject var monitor: KeyboardMonitor
    @Binding var showLogViewer: Bool
    @Binding var showSettings: Bool
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 今日の統計
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.blue)
                    Text("今日の統計")
                        .font(.headline)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 4)
                
                HStack(spacing: 20) {
                    StatItem(
                        icon: "character.cursor.ibeam",
                        label: "キー入力",
                        value: "\(monitor.todayKeystrokes)"
                    )
                    
                    StatItem(
                        icon: "command",
                        label: "ショートカット",
                        value: "\(monitor.todayShortcuts)"
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // メニュー項目
            MenuButton(
                icon: "list.bullet.rectangle",
                title: "詳細ログを見る...",
                action: { 
                    openWindow(id: "log-viewer")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            )
            
            MenuButton(
                icon: monitor.isPaused ? "play.fill" : "pause.fill",
                title: monitor.isPaused ? "記録を再開" : "記録を一時停止",
                action: { monitor.togglePause() }
            )
            
            Divider()
            
            MenuButton(
                icon: "gearshape",
                title: "設定...",
                action: { 
                    openWindow(id: "settings")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            )
            
            Divider()
            
            MenuButton(
                icon: "power",
                title: "終了",
                action: { NSApplication.shared.terminate(nil) }
            )
        }
        .frame(width: 240)
        .background(.ultraThinMaterial)
    }
}

/// 統計アイテム
struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

/// メニューボタン
struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
