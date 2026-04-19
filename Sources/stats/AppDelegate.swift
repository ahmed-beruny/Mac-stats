import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let cpuMonitor = CPUUsage()
    let ramMonitor = RAMUsage()
    let gpuMonitor = GPUUsage()
    let networkMonitor = NetworkUsage()
    var timer: Timer?
    var appMemoryItem: NSMenuItem?
    var wiredMemoryItem: NSMenuItem?
    var compressedMemoryItem: NSMenuItem?
    var gpuUsageItem: NSMenuItem?
    var downloadSpeedItem: NSMenuItem?
    var uploadSpeedItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use monospaced digit font to prevent text shaking
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.title = "Stats: --"
        }
        
        setupMenu()
        startMonitoring()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
    }

    func setupMenu() {
        let menu = NSMenu()
        
        appMemoryItem = NSMenuItem(title: "App Memory: --", action: nil, keyEquivalent: "")
        menu.addItem(appMemoryItem!)
        
        wiredMemoryItem = NSMenuItem(title: "Wired Memory: --", action: nil, keyEquivalent: "")
        menu.addItem(wiredMemoryItem!)
        
        compressedMemoryItem = NSMenuItem(title: "Compressed: --", action: nil, keyEquivalent: "")
        menu.addItem(compressedMemoryItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        gpuUsageItem = NSMenuItem(title: "GPU Usage: --", action: nil, keyEquivalent: "")
        menu.addItem(gpuUsageItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        downloadSpeedItem = NSMenuItem(title: "Download: --", action: nil, keyEquivalent: "")
        menu.addItem(downloadSpeedItem!)
        
        uploadSpeedItem = NSMenuItem(title: "Upload: --", action: nil, keyEquivalent: "")
        menu.addItem(uploadSpeedItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "About Stats Monitor", action: #selector(about), keyEquivalent: "")
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }

    @objc func about() {
        let alert = NSAlert()
        alert.messageText = "Stats Monitor"
        alert.informativeText = "A native macOS system monitor showing CPU, RAM, GPU usage, and Network activity."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func startMonitoring() {
        // Initial samples
        _ = cpuMonitor.getUsage()
        _ = ramMonitor.getUsage()
        _ = gpuMonitor.getUsage()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let cpu = self.cpuMonitor.getUsage() ?? 0.0
            let ram = self.ramMonitor.getUsage()
            let gpu = self.gpuMonitor.getUsage()
            let network = self.networkMonitor.getUsage()
            
            DispatchQueue.main.async {
                if let button = self.statusItem?.button {
                    // Fixed-width formatting for consistency
                    let cpuStr = String(format: "C:%3.0f%%", cpu)
                    
                    var ramStr = ""
                    if let ramValue = ram {
                        let formattedUsed = self.ramMonitor.formatBytes(ramValue.used)
                        ramStr = String(format: "R:%6s", (formattedUsed as NSString).utf8String!)
                        
                        // Update menu items
                        self.appMemoryItem?.title = "App Memory: \(self.ramMonitor.formatBytes(ramValue.app))"
                        self.wiredMemoryItem?.title = "Wired Memory: \(self.ramMonitor.formatBytes(ramValue.wired))"
                        self.compressedMemoryItem?.title = "Compressed: \(self.ramMonitor.formatBytes(ramValue.compressed))"
                    }

                    var gpuStr = ""
                    if let gpuValue = gpu {
                        gpuStr = String(format: "G:%2.0f%%", gpuValue.device)
                        self.gpuUsageItem?.title = String(format: "GPU Usage: %.0f%% (R:%.0f%% T:%.0f%%)", gpuValue.device, gpuValue.renderer, gpuValue.tiler)
                    }

                    var netStr = ""
                    if let netValue = network {
                        let downFormatted = self.networkMonitor.formatSpeed(netValue.downloadSpeed)
                        let upFormatted = self.networkMonitor.formatSpeed(netValue.uploadSpeed)
                        netStr = "↓\(downFormatted)"
                        
                        self.downloadSpeedItem?.title = "Download Speed: \(downFormatted)"
                        self.uploadSpeedItem?.title = "Upload Speed: \(upFormatted)"
                    }

                    button.title = "\(netStr) \(cpuStr) \(gpuStr) \(ramStr)"

                    // Update tooltip with all stats
                    let ramInfo = ram.map {
                        """
                        \nMemory Usage:
                        App Memory: \(self.ramMonitor.formatBytes($0.app))
                        Wired Memory: \(self.ramMonitor.formatBytes($0.wired))
                        Compressed: \(self.ramMonitor.formatBytes($0.compressed))
                        Total Used: \(self.ramMonitor.formatBytes($0.used))
                        """
                    } ?? ""
                    
                    let gpuInfo = gpu.map {
                        """
                        \nGPU Usage:
                        Device: \(String(format: "%.0f%%", $0.device))
                        Renderer: \(String(format: "%.0f%%", $0.renderer))
                        Tiler: \(String(format: "%.0f%%", $0.tiler))
                        """
                    } ?? ""
                    
                    let netInfo = network.map {
                        """
                        \nNetwork Activity:
                        Download: \(self.networkMonitor.formatSpeed($0.downloadSpeed))
                        Upload: \(self.networkMonitor.formatSpeed($0.uploadSpeed))
                        """
                    } ?? ""
                    
                    button.toolTip = "CPU Usage: \(String(format: "%.1f%%", cpu))\(ramInfo)\(gpuInfo)\(netInfo)"
                }
            }
        }
        timer?.tolerance = 0.1
        RunLoop.current.add(timer!, forMode: .common)
    }
}

