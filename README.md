# SystemPulse

A lightweight macOS menu bar system monitor. Displays real-time CPU, Memory, Disk, and Network usage directly in your menu bar — no need to open Activity Monitor.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Size](https://img.shields.io/badge/DMG-79KB-brightgreen)

## Features

- **Real-time monitoring** — CPU, Memory, Disk usage (%), Network speed (upload/download)
- **Menu bar display** — Always visible at a glance: `CPU 12%  MEM 62%  DSK 45%  ↑1.2KB/s ↓3.4MB/s`
- **Customizable** — Toggle each metric on/off from the dropdown menu
- **Adjustable refresh rate** — 1s / 2s / 3s / 5s intervals
- **Detailed breakdown** — Click the menu bar to see per-metric details:
  - CPU: User % / System % split
  - Memory: Used / Total with exact byte counts
  - Disk: Usage % with free space
  - Network: Upload and download speeds

## Performance

Built with pure AppKit — no SwiftUI, no Electron, no web views.

| Metric | Value |
|--------|-------|
| Memory (RSS) | ~42 MB |
| CPU usage | 0.0% |
| Binary size | 196 KB |
| DMG size | 79 KB |

For comparison, similar tools typically use 80–150 MB of memory.

## Install

### Download DMG

1. Go to [Releases](https://github.com/LowAHN/SystemPulse/releases/latest)
2. Download `SystemPulse.dmg`
3. Open the DMG and drag `SystemPulse.app` to Applications
4. Launch SystemPulse from Applications

> **Note:** This app is not signed with an Apple Developer certificate.
> On first launch, macOS may block it. To allow it:
>
> **System Settings → Privacy & Security → scroll down → click "Open Anyway"**

### Build from source

```bash
git clone https://github.com/LowAHN/SystemPulse.git
cd SystemPulse
make app
open build/SystemPulse.app
```

Requires Xcode Command Line Tools and macOS 13.0+.

## Usage

| Action | How |
|--------|-----|
| View details | Click the menu bar text |
| Toggle metrics | Click → **Display** → check/uncheck items |
| Change refresh rate | Click → **Refresh Interval** → select 1s–5s |
| Quit | Click → **Quit** (or ⌘Q) |

## Tech Stack

- **Language:** Swift
- **Framework:** Pure AppKit (no SwiftUI)
- **System APIs:** Mach kernel (`host_processor_info`, `host_statistics64`), `getifaddrs`, `FileManager`
- **Architecture:** MVVM with Combine
- **Min OS:** macOS 13.0 (Ventura)
- **Dependencies:** None

## License

MIT
