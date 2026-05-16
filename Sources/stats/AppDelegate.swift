import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let cpuMonitor = CPUUsage()
    let gpuMonitor = GPUUsage()
    var timer: Timer?
    var cpuUsageItem: NSMenuItem?
    var gpuUsageItem: NSMenuItem?

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
        
        cpuUsageItem = NSMenuItem(title: "CPU Usage: --", action: nil, keyEquivalent: "")
        menu.addItem(cpuUsageItem!)
        
        gpuUsageItem = NSMenuItem(title: "GPU Usage: --", action: nil, keyEquivalent: "")
        menu.addItem(gpuUsageItem!)
        
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
        alert.informativeText = "A native macOS system monitor showing CPU and GPU usage."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func startMonitoring() {
        // Initial samples
        _ = cpuMonitor.getUsage()
        _ = gpuMonitor.getUsage()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let cpu = self.cpuMonitor.getUsage() ?? 0.0
            let gpu = self.gpuMonitor.getUsage()
            
            DispatchQueue.main.async {
                if let button = self.statusItem?.button {
                    // Fixed-width formatting for consistency
                    let cpuStr = String(format: "C:%3.0f%%", cpu)
                    self.cpuUsageItem?.title = String(format: "CPU Usage: %.1f%%", cpu)
                    
                    var gpuStr = ""
                    if let gpuValue = gpu {
                        gpuStr = String(format: "G:%2.0f%%", gpuValue.device)
                        self.gpuUsageItem?.title = String(format: "GPU Usage: %.0f%% (R:%.0f%% T:%.0f%%)", gpuValue.device, gpuValue.renderer, gpuValue.tiler)
                    }

                    button.title = "\(cpuStr) \(gpuStr)"

                    let gpuInfo = gpu.map {
                        """
                        \nGPU Usage:
                        Device: \(String(format: "%.0f%%", $0.device))
                        Renderer: \(String(format: "%.0f%%", $0.renderer))
                        Tiler: \(String(format: "%.0f%%", $0.tiler))
                        """
                    } ?? ""
                    
                    button.toolTip = "CPU Usage: \(String(format: "%.1f%%", cpu))\(gpuInfo)"
                }
            }
        }
        timer?.tolerance = 0.1
        RunLoop.current.add(timer!, forMode: .common)
    }
}

