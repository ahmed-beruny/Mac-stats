import Foundation
import MachO

class CPUUsage {
    private var previousLoad: host_cpu_load_info?

    func getUsage() -> Double? {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var cpuLoad = host_cpu_load_info()
        
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        guard result == KERN_SUCCESS else { return nil }
        
        guard let prev = previousLoad else {
            previousLoad = cpuLoad
            return 0.0
        }
        
        // cpu_ticks is a tuple of 4 uint32_t: (user, system, idle, nice)
        let user = cpuLoad.cpu_ticks.0
        let system = cpuLoad.cpu_ticks.1
        let idle = cpuLoad.cpu_ticks.2
        let nice = cpuLoad.cpu_ticks.3
        
        let prevUser = prev.cpu_ticks.0
        let prevSystem = prev.cpu_ticks.1
        let prevIdle = prev.cpu_ticks.2
        let prevNice = prev.cpu_ticks.3
        
        let userDiff = Double(user >= prevUser ? user - prevUser : (UInt32.max - prevUser) + user)
        let systemDiff = Double(system >= prevSystem ? system - prevSystem : (UInt32.max - prevSystem) + system)
        let idleDiff = Double(idle >= prevIdle ? idle - prevIdle : (UInt32.max - prevIdle) + idle)
        let niceDiff = Double(nice >= prevNice ? nice - prevNice : (UInt32.max - prevNice) + nice)
        
        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
        let usedTicks = userDiff + systemDiff + niceDiff
        
        previousLoad = cpuLoad
        
        if totalTicks == 0 { return 0.0 }
        return (usedTicks / totalTicks) * 100.0
    }
}
