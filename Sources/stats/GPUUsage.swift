import Foundation
import IOKit

struct GPUStats {
    let device: Double
    let renderer: Double
    let tiler: Double
}

class GPUUsage {
    func getUsage() -> GPUStats? {
        let matchDict = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
        guard result == kIOReturnSuccess else { return nil }
        
        defer {
            IOObjectRelease(iterator)
        }
        
        var deviceUtil = 0.0
        var rendererUtil = 0.0
        var tilerUtil = 0.0
        var found = false
        
        var regEntry = IOIteratorNext(iterator)
        while regEntry != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(regEntry, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess {
                if let dict = props?.takeRetainedValue() as? [String: Any],
                   let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                    
                    // On most systems, "Device Utilization %" is the main one.
                    // Fallback to "Utilization %" if "Device Utilization %" is not found.
                    if let val = (perfStats["Device Utilization %"] ?? perfStats["Utilization %"]) as? Double {
                        deviceUtil = max(deviceUtil, val)
                        found = true
                    } else if let val = (perfStats["Device Utilization %"] ?? perfStats["Utilization %"]) as? Int {
                        deviceUtil = max(deviceUtil, Double(val))
                        found = true
                    }
                    
                    if let val = perfStats["Renderer Utilization %"] as? Double {
                        rendererUtil = max(rendererUtil, val)
                    } else if let val = perfStats["Renderer Utilization %"] as? Int {
                        rendererUtil = max(rendererUtil, Double(val))
                    }
                    
                    if let val = perfStats["Tiler Utilization %"] as? Double {
                        tilerUtil = max(tilerUtil, val)
                    } else if let val = perfStats["Tiler Utilization %"] as? Int {
                        tilerUtil = max(tilerUtil, Double(val))
                    }
                }
            }
            IOObjectRelease(regEntry)
            regEntry = IOIteratorNext(iterator)
        }
        
        return found ? GPUStats(device: deviceUtil, renderer: rendererUtil, tiler: tilerUtil) : nil
    }
}
