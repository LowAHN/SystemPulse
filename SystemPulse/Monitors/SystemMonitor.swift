import Foundation
import Combine

final class SystemMonitor: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private lazy var diskMonitor = DiskMonitor()
    private lazy var networkMonitor = NetworkMonitor()

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.systempulse.monitor", qos: .utility)

    // Only sample what's enabled
    var enabledMetrics: Set<MetricType> = [] {
        didSet { /* takes effect on next tick */ }
    }

    var updateInterval: TimeInterval {
        didSet { restartTimer() }
    }

    private static let zeroCPU = CPUMetrics(userPercent: 0, systemPercent: 0, idlePercent: 100)
    private static let zeroMemory = MemoryMetrics(
        totalBytes: 0, usedBytes: 0, freeBytes: 0,
        activeBytes: 0, wiredBytes: 0, compressedBytes: 0
    )
    private static let zeroDisk = DiskMetrics(totalBytes: 0, usedBytes: 0, freeBytes: 0)
    private static let zeroNetwork = NetworkMetrics(uploadBytesPerSecond: 0, downloadBytesPerSecond: 0)

    init(updateInterval: TimeInterval = 3.0, enabledMetrics: Set<MetricType> = Set(MetricType.allCases)) {
        self.updateInterval = updateInterval
        self.enabledMetrics = enabledMetrics
        self.snapshot = SystemSnapshot(
            cpu: Self.zeroCPU,
            memory: Self.zeroMemory,
            disk: Self.zeroDisk,
            network: Self.zeroNetwork,
            timestamp: Date()
        )
    }

    func start() {
        sampleAll()
        restartTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func restartTimer() {
        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + updateInterval, repeating: updateInterval)
        t.setEventHandler { [weak self] in
            self?.sampleAll()
        }
        t.resume()
        timer = t
    }

    private func sampleAll() {
        let enabled = enabledMetrics

        // Only sample enabled metrics to save CPU cycles
        let cpu = enabled.contains(.cpu) ? cpuMonitor.sample() : Self.zeroCPU
        let memory = enabled.contains(.memory) ? memoryMonitor.sample() : Self.zeroMemory
        let disk = enabled.contains(.disk) ? diskMonitor.sample() : Self.zeroDisk
        let network = enabled.contains(.network) ? networkMonitor.sample() : Self.zeroNetwork

        let snap = SystemSnapshot(
            cpu: cpu, memory: memory, disk: disk, network: network,
            timestamp: Date()
        )

        DispatchQueue.main.async { [weak self] in
            self?.snapshot = snap
        }
    }
}
