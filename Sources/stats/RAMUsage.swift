import Foundation
import MachO

class RAMUsage {
    func getUsage() -> (used: Double, total: Double)? {
        var hostPort = mach_host_self()
        var hostSize = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &hostSize)
            }
        }
        
        guard result == KERN_SUCCESS else { return nil }
        
        let pageSize = UInt64(vm_kernel_page_size)
        
        // Memory usage categories
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        
        let usedMemory = Double(active + wired + compressed)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        
        return (usedMemory, totalMemory)
    }
    
    func formatBytes(_ bytes: Double) -> String {
        let gb = bytes / pow(1024, 3)
        return String(format: "%.1fGB", gb)
    }
}
