import Foundation
import Combine

final class PreferencesStore: ObservableObject {
    @Published var enabledMetrics: Set<MetricType> {
        didSet { saveMetrics() }
    }
    @Published var updateInterval: TimeInterval {
        didSet { UserDefaults.standard.set(updateInterval, forKey: Keys.updateInterval) }
    }

    private enum Keys {
        static let enabledMetrics = "enabledMetrics"
        static let updateInterval = "updateInterval"
    }

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: Keys.enabledMetrics) {
            enabledMetrics = Set(saved.compactMap { MetricType(rawValue: $0) })
        } else {
            enabledMetrics = Set(MetricType.allCases.filter(\.defaultEnabled))
        }
        let interval = UserDefaults.standard.double(forKey: Keys.updateInterval)
        updateInterval = interval > 0 ? interval : 3.0
    }

    func toggle(_ metric: MetricType) {
        if enabledMetrics.contains(metric) {
            guard enabledMetrics.count > 1 else { return }
            enabledMetrics.remove(metric)
        } else {
            enabledMetrics.insert(metric)
        }
    }

    func isEnabled(_ metric: MetricType) -> Bool {
        enabledMetrics.contains(metric)
    }

    private func saveMetrics() {
        UserDefaults.standard.set(enabledMetrics.map(\.rawValue), forKey: Keys.enabledMetrics)
    }
}
