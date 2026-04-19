# stats

A lightweight macOS menu bar utility that provides real-time monitoring of system CPU and RAM usage.

![Sample](https://img.shields.io/badge/macOS-v14+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)

## Features

- **CPU Monitoring**: Displays real-time CPU load percentage in the menu bar.
- **RAM Monitoring**: Displays current memory usage.
- **Native Integration**: Built with Swift and AppKit for a native macOS feel.
- **Auto-start support**: Includes a script to easily configure the app to run on system startup.

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Swift 6.0+

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/ahmedberuny/stats.git
   cd stats
   ```

2. Build the application:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

### Running the App

After building, you can start the application manually:
```bash
./.build/debug/stats &
```

## Configuring Auto-start

To make the application start automatically every time you log in to your Mac, run the provided setup script:

```bash
chmod +x setup_autostart.sh
./setup_autostart.sh
```

This will create a Launch Agent at `~/Library/LaunchAgents/com.ahmedberuny.stats.plist` that manages the application process.

## Development

The project is structured as a standard Swift Package:

- `Sources/stats/main.swift`: Entry point of the application.
- `Sources/stats/AppDelegate.swift`: Manages the menu bar icon and UI updates.
- `Sources/stats/CPUUsage.swift`: Logic for fetching CPU statistics.
- `Sources/stats/RAMUsage.swift`: Logic for fetching RAM statistics.

## License

[MIT License](LICENSE) (or specify your license here)
