import Foundation

struct NetworkStats {
    let downloadSpeed: Double // Bytes per second
    let uploadSpeed: Double   // Bytes per second
}

class NetworkUsage {
    private var prevInBytes: UInt64 = 0
    private var prevOutBytes: UInt64 = 0
    private var lastCheckTime: Date?

    func getUsage() -> NetworkStats? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee
            let addr = interface.ifa_addr.pointee
            
            // Check if it's a link-layer interface (AF_LINK)
            if addr.sa_family == UInt8(AF_LINK) {
                // On macOS, ifa_data points to if_data or if_data64. 
                // We'll use if_data and handle potential 32-bit overflows by looking at deltas.
                if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    let name = String(cString: interface.ifa_name)
                    // Skip loopback and other non-physical interfaces if needed, 
                    // but usually summing all is fine for "system" stats.
                    if !name.hasPrefix("lo") {
                        totalIn += UInt64(data.pointee.ifi_ibytes)
                        totalOut += UInt64(data.pointee.ifi_obytes)
                    }
                }
            }
            ptr = interface.ifa_next
        }

        let now = Date()
        guard let prevTime = lastCheckTime else {
            prevInBytes = totalIn
            prevOutBytes = totalOut
            lastCheckTime = now
            return NetworkStats(downloadSpeed: 0, uploadSpeed: 0)
        }

        let timeDiff = now.timeIntervalSince(prevTime)
        if timeDiff <= 0 { return nil }

        // Calculate deltas, handling overflows (32-bit wrapping)
        let downDiff: UInt64
        if totalIn >= prevInBytes {
            downDiff = totalIn - prevInBytes
        } else {
            // Handle 32-bit overflow (since if_data uses 32-bit counters on some macOS versions)
            downDiff = (UInt64(UInt32.max) - prevInBytes) + totalIn + 1
        }

        let upDiff: UInt64
        if totalOut >= prevOutBytes {
            upDiff = totalOut - prevOutBytes
        } else {
            upDiff = (UInt64(UInt32.max) - prevOutBytes) + totalOut + 1
        }

        let downSpeed = Double(downDiff) / timeDiff
        let upSpeed = Double(upDiff) / timeDiff

        prevInBytes = totalIn
        prevOutBytes = totalOut
        lastCheckTime = now

        return NetworkStats(downloadSpeed: downSpeed, uploadSpeed: upSpeed)
    }

    func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.1f GB/s", bytesPerSecond / (1024 * 1024 * 1024))
        }
    }
}
