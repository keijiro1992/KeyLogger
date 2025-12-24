import SwiftUI

/// 統計表示ビュー（メニューバー内用）
struct StatsView: View {
    @ObservedObject var monitor: KeyboardMonitor
    
    var body: some View {
        VStack(spacing: 16) {
            // 今日の統計
            HStack(spacing: 24) {
                StatCard(
                    title: "キー入力",
                    value: monitor.todayKeystrokes,
                    icon: "keyboard",
                    color: .blue
                )
                
                StatCard(
                    title: "ショートカット",
                    value: monitor.todayShortcuts,
                    icon: "command",
                    color: .purple
                )
            }
            
            // ステータス
            HStack {
                Circle()
                    .fill(monitor.isPaused ? .orange : .green)
                    .frame(width: 8, height: 8)
                
                Text(monitor.isPaused ? "一時停止中" : "記録中")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

/// 統計カード
struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 100)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
