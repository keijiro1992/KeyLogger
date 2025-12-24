import SwiftUI
import ServiceManagement

/// 設定ビュー
struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("retentionDays") private var retentionDays = 7
    @State private var excludedApps: [String] = []
    @State private var newAppBundleId = ""
    @State private var isCleaningUp = false
    @State private var showingCleanupAlert = false
    
    var body: some View {
        Form {
            // 一般設定
            Section("一般") {
                Toggle("ログイン時に起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(enabled: newValue)
                    }
            }
            
            // データ保持設定
            Section("データ保持") {
                Picker("ログ保持期間", selection: $retentionDays) {
                    Text("3日").tag(3)
                    Text("7日（1週間）").tag(7)
                    Text("14日（2週間）").tag(14)
                    Text("30日（1ヶ月）").tag(30)
                }
                
                Button(action: cleanupOldData) {
                    HStack {
                        if isCleaningUp {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("古いログを今すぐ削除")
                    }
                }
                .disabled(isCleaningUp)
            }
            
            // プライバシー設定
            Section("プライバシー") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("除外するアプリ")
                        .font(.headline)
                    
                    Text("以下のアプリでのキー入力は記録されません")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    List {
                        ForEach(getDefaultExcludedApps(), id: \.self) { app in
                            HStack {
                                Text(app)
                                Spacer()
                                Text("デフォルト")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 120)
                }
            }
            
            // 権限設定
            Section("権限") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("アクセシビリティ")
                            .font(.headline)
                        Text("キーボード入力を監視するために必要です")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if PermissionManager.isAccessibilityGranted() {
                        Label("許可済み", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("設定を開く") {
                            PermissionManager.openAccessibilityPreferences()
                        }
                    }
                }
            }
            
            // アプリ情報
            Section("情報") {
                LabeledContent("バージョン", value: "1.0.0")
                LabeledContent("データ保存先", value: getDataPath())
                
                Button("データフォルダを開く") {
                    openDataFolder()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 500)
        .alert("クリーンアップ完了", isPresented: $showingCleanupAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("古いログデータが削除されました")
        }
    }
    
    /// デフォルトの除外アプリを取得
    private func getDefaultExcludedApps() -> [String] {
        return [
            "1Password",
            "LastPass",
            "Bitwarden",
            "Keychain Access"
        ]
    }
    
    /// ログイン時自動起動を設定
    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
    
    /// 古いデータをクリーンアップ
    private func cleanupOldData() {
        isCleaningUp = true
        
        Task {
            do {
                try await DatabaseManager.shared.cleanupOldEvents()
                showingCleanupAlert = true
            } catch {
                print("Failed to cleanup: \(error)")
            }
            isCleaningUp = false
        }
    }
    
    /// データパスを取得
    private func getDataPath() -> String {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupportURL.appendingPathComponent("KeyLogger").path
    }
    
    /// データフォルダを開く
    private func openDataFolder() {
        let path = getDataPath()
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
