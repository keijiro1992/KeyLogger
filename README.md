# KeyLogger

A macOS menu bar app that tracks your keyboard usage with heatmap visualization, shortcut detection, and app-based statistics.

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- ✅ **Full Keystroke Logging** - Records all keyboard inputs with timestamps
- ✅ **Shortcut Detection** - Identifies ⌘/⌃/⌥ key combinations
- ✅ **Keyboard Heatmap** - Visual representation of key usage frequency
- ✅ **Hourly Statistics** - Track your typing patterns throughout the day
- ✅ **App-based Statistics** - See which apps you type in most
- ✅ **Password Field Exclusion** - Automatically skips secure text inputs
- ✅ **7-Day Auto-Cleanup** - Old logs are automatically deleted
- ✅ **Menu Bar App** - Lightweight, always accessible from menu bar

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)
- Swift 5.9 or later

## Installation

### Build from Source

```bash
git clone https://github.com/keijiro1992/KeyLogger.git
cd KeyLogger
swift build -c release
```

### Run

```bash
.build/release/KeyLogger
```

## Permissions

This app requires **Accessibility** permission to monitor keyboard events.

1. Open **System Settings**
2. Go to **Privacy & Security** → **Accessibility**
3. Add and enable the app (or Terminal if running from command line)

## Privacy

- **Password managers** (1Password, LastPass, etc.) are automatically excluded
- **Secure text fields** are automatically skipped
- **Data is stored locally only** - no external transmission
- **Logs older than 7 days** are automatically deleted

## Project Structure

```
KeyLogger/
├── Package.swift              # Swift Package Manager config
├── KeyLogger/
│   ├── App/
│   │   ├── KeyLoggerApp.swift     # App entry point
│   │   └── AppDelegate.swift      # App delegate
│   ├── Core/
│   │   └── KeyboardMonitor.swift  # Keyboard monitoring (CGEvent Tap)
│   ├── Models/
│   │   └── KeyEvent.swift         # Data models
│   ├── Database/
│   │   └── DatabaseManager.swift  # SQLite database management
│   ├── Views/
│   │   ├── MenuBarView.swift      # Menu bar dropdown
│   │   ├── KeyboardHeatmapView.swift  # Keyboard heatmap
│   │   ├── LogViewerView.swift    # Log viewer with charts
│   │   ├── SettingsView.swift     # Settings window
│   │   └── StatsView.swift        # Statistics components
│   └── Utils/
│       ├── KeyCodeMapper.swift    # Key code to name mapping
│       └── PermissionManager.swift # Accessibility permission
└── KeyLoggerTests/
    └── KeyLoggerTests.swift       # Unit tests
```

## License

MIT License - see [LICENSE](LICENSE) for details.
