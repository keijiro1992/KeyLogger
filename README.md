# KeyLogger

macOSでバックグラウンド動作するキーボード入力ログアプリケーション。

## 機能

- ✅ **全キー入力の記録**: すべてのキーボード入力をタイムスタンプ付きで記録
- ✅ **ショートカット検出**: Command, Control, Option との組み合わせを識別
- ✅ **パスワードフィールド除外**: セキュアテキスト入力は自動的にスキップ
- ✅ **アプリ別統計**: どのアプリでどれだけ入力したかを表示
- ✅ **時間帯別統計**: 1日の中でどの時間帯に多く入力したかをグラフ表示
- ✅ **1週間の自動削除**: 7日以上前のログは自動的に削除
- ✅ **メニューバーアプリ**: 常駐型でリソース消費を最小限に

## 必要要件

- macOS 13.0 以上
- Xcode 15.0 以上
- Swift 5.9 以上

## インストール

### ビルド方法

```bash
cd KeyLogger
swift build -c release
```

### Xcodeで開く場合

```bash
cd KeyLogger
open Package.swift
```

## 権限設定

このアプリケーションはキーボード入力を監視するため、**アクセシビリティ権限**が必要です。

1. 「システム設定」を開く
2. 「プライバシーとセキュリティ」→「アクセシビリティ」へ移動
3. KeyLoggerアプリを追加して権限を許可

## 使い方

1. アプリを起動すると、メニューバーにキーボードアイコンが表示されます
2. アイコンをクリックすると、今日の統計が表示されます
3. 「詳細ログを見る」で時間帯別・アプリ別の統計を確認できます
4. 「設定」でログイン時の自動起動などを設定できます

## プライバシー保護

- パスワードマネージャー（1Password, LastPass等）での入力は自動除外
- パスワードフィールドでの入力は自動除外
- データはローカルのみに保存（外部送信なし）
- 7日以上前のデータは自動削除

## ディレクトリ構成

```
KeyLogger/
├── Package.swift          # Swift Package Manager設定
├── KeyLogger/
│   ├── App/
│   │   ├── KeyLoggerApp.swift     # アプリエントリーポイント
│   │   └── AppDelegate.swift      # アプリデリゲート
│   ├── Core/
│   │   └── KeyboardMonitor.swift  # キーボード監視
│   ├── Models/
│   │   └── KeyEvent.swift         # データモデル
│   ├── Database/
│   │   └── DatabaseManager.swift  # データベース管理
│   ├── Views/
│   │   ├── MenuBarView.swift      # メニューバーUI
│   │   ├── LogViewerView.swift    # ログビューア
│   │   ├── SettingsView.swift     # 設定画面
│   │   └── StatsView.swift        # 統計表示
│   └── Utils/
│       ├── KeyCodeMapper.swift    # キーコード変換
│       └── PermissionManager.swift # 権限管理
└── README.md
```

## ライセンス

MIT License
