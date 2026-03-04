import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var systemMonitor: SystemMonitor!
    private var preferences: PreferencesStore!
    private var cancellables = Set<AnyCancellable>()

    // Cache font
    private static let menuBarFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    private static let menuBarAttrs: [NSAttributedString.Key: Any] = [.font: menuBarFont]

    override init() {
        self.preferences = PreferencesStore()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        systemMonitor = SystemMonitor(
            updateInterval: preferences.updateInterval,
            enabledMetrics: preferences.enabledMetrics
        )

        // Build the dropdown menu
        rebuildMenu()

        // Update menu bar text on snapshot changes
        systemMonitor.$snapshot
            .combineLatest(preferences.$enabledMetrics)
            .map { snapshot, enabled in
                Self.formatMenuBarString(snapshot: snapshot, enabled: enabled)
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.statusItem.button?.attributedTitle = NSAttributedString(
                    string: text, attributes: Self.menuBarAttrs
                )
            }
            .store(in: &cancellables)

        // Rebuild menu when metrics change
        preferences.$enabledMetrics
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] metrics in
                self?.systemMonitor.enabledMetrics = metrics
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        preferences.$updateInterval
            .dropFirst()
            .sink { [weak self] interval in
                self?.systemMonitor.updateInterval = interval
            }
            .store(in: &cancellables)

        // Update detail items in the menu
        systemMonitor.$snapshot
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.updateDetailMenu(snapshot: snapshot)
            }
            .store(in: &cancellables)

        systemMonitor.start()
    }

    // MARK: - Menu

    private var cpuDetailItem: NSMenuItem?
    private var memDetailItem: NSMenuItem?
    private var diskDetailItem: NSMenuItem?
    private var netUpItem: NSMenuItem?
    private var netDownItem: NSMenuItem?

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Detail section
        let header = NSMenuItem(title: "SystemPulse", action: nil, keyEquivalent: "")
        header.isEnabled = false
        header.attributedTitle = NSAttributedString(
            string: "SystemPulse",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        let cpuItem = NSMenuItem(title: "CPU: —", action: nil, keyEquivalent: "")
        cpuItem.isEnabled = false
        cpuDetailItem = cpuItem
        menu.addItem(cpuItem)

        let memItem = NSMenuItem(title: "Memory: —", action: nil, keyEquivalent: "")
        memItem.isEnabled = false
        memDetailItem = memItem
        menu.addItem(memItem)

        let dskItem = NSMenuItem(title: "Disk: —", action: nil, keyEquivalent: "")
        dskItem.isEnabled = false
        diskDetailItem = dskItem
        menu.addItem(dskItem)

        let netUp = NSMenuItem(title: "↑ Upload: —", action: nil, keyEquivalent: "")
        netUp.isEnabled = false
        netUpItem = netUp
        menu.addItem(netUp)

        let netDown = NSMenuItem(title: "↓ Download: —", action: nil, keyEquivalent: "")
        netDown.isEnabled = false
        netDownItem = netDown
        menu.addItem(netDown)

        menu.addItem(NSMenuItem.separator())

        // Toggle metrics submenu
        let displayMenu = NSMenu()
        for metric in MetricType.allCases {
            let item = NSMenuItem(
                title: metric.rawValue,
                action: #selector(toggleMetric(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = metric
            item.state = preferences.isEnabled(metric) ? .on : .off
            displayMenu.addItem(item)
        }
        let displayItem = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
        displayItem.submenu = displayMenu
        menu.addItem(displayItem)

        // Refresh interval submenu
        let intervalMenu = NSMenu()
        for interval: TimeInterval in [1, 2, 3, 5] {
            let item = NSMenuItem(
                title: "\(Int(interval))s",
                action: #selector(setInterval(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = Int(interval)
            item.state = preferences.updateInterval == interval ? .on : .off
            intervalMenu.addItem(item)
        }
        let intervalItem = NSMenuItem(title: "Refresh Interval", action: nil, keyEquivalent: "")
        intervalItem.submenu = intervalMenu
        menu.addItem(intervalItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateDetailMenu(snapshot: SystemSnapshot) {
        cpuDetailItem?.title = String(
            format: "CPU: %.1f%% (User %.1f%% / Sys %.1f%%)",
            snapshot.cpu.totalUsage, snapshot.cpu.userPercent, snapshot.cpu.systemPercent
        )
        memDetailItem?.title = String(
            format: "Memory: %.1f%% (%@ / %@)",
            snapshot.memory.usagePercent,
            ByteCountFormatter.humanReadable(snapshot.memory.usedBytes),
            ByteCountFormatter.humanReadable(snapshot.memory.totalBytes)
        )
        diskDetailItem?.title = String(
            format: "Disk: %.1f%% (Free: %@)",
            snapshot.disk.usagePercent,
            ByteCountFormatter.humanReadable(snapshot.disk.freeBytes)
        )
        netUpItem?.title = "↑ Upload: \(ByteCountFormatter.shortRate(snapshot.network.uploadBytesPerSecond))"
        netDownItem?.title = "↓ Download: \(ByteCountFormatter.shortRate(snapshot.network.downloadBytesPerSecond))"
    }

    @objc private func toggleMetric(_ sender: NSMenuItem) {
        guard let metric = sender.representedObject as? MetricType else { return }
        preferences.toggle(metric)
        sender.state = preferences.isEnabled(metric) ? .on : .off
    }

    @objc private func setInterval(_ sender: NSMenuItem) {
        let interval = TimeInterval(sender.tag)
        preferences.updateInterval = interval
        // Update checkmarks
        if let menu = sender.menu {
            for item in menu.items {
                item.state = item.tag == sender.tag ? .on : .off
            }
        }
    }

    // MARK: - Formatting

    private static func formatMenuBarString(
        snapshot: SystemSnapshot,
        enabled: Set<MetricType>
    ) -> String {
        var segments: [String] = []

        if enabled.contains(.cpu) {
            segments.append(String(format: "CPU %.0f%%", snapshot.cpu.totalUsage))
        }
        if enabled.contains(.memory) {
            segments.append(String(format: "MEM %.0f%%", snapshot.memory.usagePercent))
        }
        if enabled.contains(.disk) {
            segments.append(String(format: "DSK %.0f%%", snapshot.disk.usagePercent))
        }
        if enabled.contains(.network) {
            let up = ByteCountFormatter.shortRate(snapshot.network.uploadBytesPerSecond)
            let dn = ByteCountFormatter.shortRate(snapshot.network.downloadBytesPerSecond)
            segments.append("↑\(up) ↓\(dn)")
        }

        return segments.isEmpty ? "—" : segments.joined(separator: "  ")
    }
}
