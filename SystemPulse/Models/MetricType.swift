import Foundation

enum MetricType: String, CaseIterable, Identifiable, Codable {
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
    case network = "Network"

    var id: String { rawValue }

    var defaultEnabled: Bool {
        switch self {
        case .cpu, .memory: return true
        case .disk, .network: return false
        }
    }

    var sfSymbol: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "network"
        }
    }

    var displayLabel: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "MEM"
        case .disk: return "DSK"
        case .network: return "NET"
        }
    }
}
