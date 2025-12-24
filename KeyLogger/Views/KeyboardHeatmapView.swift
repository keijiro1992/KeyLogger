import SwiftUI

/// キーボードヒートマップビュー
struct KeyboardHeatmapView: View {
    let keyFrequency: [String: Int]
    let maxCount: Int
    
    // US配列キーボードレイアウト
    private let keyboardRows: [[KeyDefinition]] = [
        // 数字行
        [
            KeyDefinition(key: "`", width: 1), KeyDefinition(key: "1", width: 1),
            KeyDefinition(key: "2", width: 1), KeyDefinition(key: "3", width: 1),
            KeyDefinition(key: "4", width: 1), KeyDefinition(key: "5", width: 1),
            KeyDefinition(key: "6", width: 1), KeyDefinition(key: "7", width: 1),
            KeyDefinition(key: "8", width: 1), KeyDefinition(key: "9", width: 1),
            KeyDefinition(key: "0", width: 1), KeyDefinition(key: "-", width: 1),
            KeyDefinition(key: "=", width: 1), KeyDefinition(key: "Delete", width: 1.5)
        ],
        // QWERTY行
        [
            KeyDefinition(key: "Tab", width: 1.5), KeyDefinition(key: "Q", width: 1),
            KeyDefinition(key: "W", width: 1), KeyDefinition(key: "E", width: 1),
            KeyDefinition(key: "R", width: 1), KeyDefinition(key: "T", width: 1),
            KeyDefinition(key: "Y", width: 1), KeyDefinition(key: "U", width: 1),
            KeyDefinition(key: "I", width: 1), KeyDefinition(key: "O", width: 1),
            KeyDefinition(key: "P", width: 1), KeyDefinition(key: "[", width: 1),
            KeyDefinition(key: "]", width: 1), KeyDefinition(key: "\\", width: 1)
        ],
        // ASDF行
        [
            KeyDefinition(key: "CapsLock", width: 1.75), KeyDefinition(key: "A", width: 1),
            KeyDefinition(key: "S", width: 1), KeyDefinition(key: "D", width: 1),
            KeyDefinition(key: "F", width: 1), KeyDefinition(key: "G", width: 1),
            KeyDefinition(key: "H", width: 1), KeyDefinition(key: "J", width: 1),
            KeyDefinition(key: "K", width: 1), KeyDefinition(key: "L", width: 1),
            KeyDefinition(key: ";", width: 1), KeyDefinition(key: "'", width: 1),
            KeyDefinition(key: "Return", width: 1.75)
        ],
        // ZXCV行
        [
            KeyDefinition(key: "Shift", width: 2.25), KeyDefinition(key: "Z", width: 1),
            KeyDefinition(key: "X", width: 1), KeyDefinition(key: "C", width: 1),
            KeyDefinition(key: "V", width: 1), KeyDefinition(key: "B", width: 1),
            KeyDefinition(key: "N", width: 1), KeyDefinition(key: "M", width: 1),
            KeyDefinition(key: ",", width: 1), KeyDefinition(key: ".", width: 1),
            KeyDefinition(key: "/", width: 1), KeyDefinition(key: "RightShift", width: 2.25)
        ],
        // スペース行
        [
            KeyDefinition(key: "Control", width: 1.25), KeyDefinition(key: "Option", width: 1.25),
            KeyDefinition(key: "Command", width: 1.5), KeyDefinition(key: "Space", width: 6),
            KeyDefinition(key: "RightCommand", width: 1.5), KeyDefinition(key: "RightOption", width: 1.25),
            KeyDefinition(key: "←", width: 1), KeyDefinition(key: "↓", width: 1), KeyDefinition(key: "→", width: 1)
        ]
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(keyboardRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    ForEach(row) { keyDef in
                        KeyView(
                            keyDef: keyDef,
                            count: keyFrequency[keyDef.key] ?? 0,
                            maxCount: maxCount
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

/// キー定義
struct KeyDefinition: Identifiable {
    let id = UUID()
    let key: String
    let width: Double
    
    var displayLabel: String {
        switch key {
        case "Delete": return "⌫"
        case "Tab": return "⇥"
        case "CapsLock": return "⇪"
        case "Return": return "↵"
        case "Shift", "RightShift": return "⇧"
        case "Control": return "⌃"
        case "Option", "RightOption": return "⌥"
        case "Command", "RightCommand": return "⌘"
        case "Space": return "Space"
        default: return key
        }
    }
}

/// 個別キービュー
struct KeyView: View {
    let keyDef: KeyDefinition
    let count: Int
    let maxCount: Int
    
    private var intensity: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
    
    private var backgroundColor: Color {
        if count == 0 {
            return Color(.controlBackgroundColor)
        }
        // 青から赤へのグラデーション
        let hue = 0.6 - (intensity * 0.6) // 青(0.6) → 赤(0)
        return Color(hue: hue, saturation: 0.7 + (intensity * 0.3), brightness: 0.9)
    }
    
    private var textColor: Color {
        intensity > 0.5 ? .white : .primary
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(keyDef.displayLabel)
                .font(.system(size: keyDef.width > 1.5 ? 10 : 12, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
        }
        .foregroundColor(textColor)
        .frame(width: keyDef.width * 40, height: 44)
        .background(backgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: count > 0 ? backgroundColor.opacity(0.5) : .clear, radius: intensity * 4)
    }
}

/// ヒートマップ凡例
struct HeatmapLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("少")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LinearGradient(
                colors: [
                    Color(hue: 0.6, saturation: 0.7, brightness: 0.9),
                    Color(hue: 0.4, saturation: 0.8, brightness: 0.9),
                    Color(hue: 0.2, saturation: 0.9, brightness: 0.9),
                    Color(hue: 0.0, saturation: 1.0, brightness: 0.9)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 120, height: 16)
            .cornerRadius(4)
            
            Text("多")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
