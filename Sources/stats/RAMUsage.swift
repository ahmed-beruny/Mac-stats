import Foundation
import MachO

struct RAMStats {
    let app: Double
    let wired: Double
    let compressed: Double
    let total: Double
    
    var used: Double {
        return app + wired + compressed
    }
}

class RAMUsage {
    func getUsage() -> RAMStats? {
        var hostPort = mach_host_self()
        var hostSize = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &hostSize)
            }
        }
        
        guard result == KERN_SUCCESS else { return nil }
        
        let pageSize = Double(vm_kernel_page_size)
        
        // Activity Monitor formula: 
        // App Memory = Internal - Purgeable
        // Used = App Memory + Wired + Compressed
        
        let internalPages = Double(vmStats.internal_page_count) * pageSize
        let purgeablePages = Double(vmStats.purgeable_count) * pageSize
        let wiredPages = Double(vmStats.wire_count) * pageSize
        let compressedPages = Double(vmStats.compressor_page_count) * pageSize
        
        let appMemory = internalPages - purgeablePages
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        
        return RAMStats(
            app: appMemory,
            wired: wiredPages,
            compressed: compressedPages,
            total: totalMemory
        )
    }
    
    func formatBytes(_ bytes: Double) -> String {
        let gb = bytes / pow(1024, 3)
        return String(format: "%.1fGB", gb)
    }
}

