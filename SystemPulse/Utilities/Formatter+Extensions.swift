import Foundation

extension ByteCountFormatter {
    static func humanReadable(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func shortRate(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond < 1024 {
            return "\(bytesPerSecond) B/s"
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        let base = formatter.string(fromByteCount: Int64(bytesPerSecond))
        return "\(base)/s"
    }
}
