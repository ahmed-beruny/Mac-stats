import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let cpuMonitor = CPUUsage()
    let ramMonitor = RAMUsage()
    var timer: Timer?

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
        alert.informativeText = "A native macOS system monitor showing CPU and RAM usage."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func startMonitoring() {
        // Initial samples
        _ = cpuMonitor.getUsage()
        _ = ramMonitor.getUsage()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let cpu = self.cpuMonitor.getUsage() ?? 0.0
            let ram = self.ramMonitor.getUsage()
            
            DispatchQueue.main.async {
                if let button = self.statusItem?.button {
                    // Fixed-width formatting for consistency
                    let cpuStr = String(format: "C:%3.0f%% ", cpu)
                    
                    var ramStr = ""
                    if let ram = ram {
                        // Pad to fixed width (e.g., " 4.2GB")
                        let formattedRAM = self.ramMonitor.formatBytes(ram.used)
                        ramStr = String(format: "R:%6s", (formattedRAM as NSString).utf8String!)
                    }
                    
                    button.title = "\(cpuStr)\(ramStr)"
                }
            }
        }
        timer?.tolerance = 0.1
        RunLoop.current.add(timer!, forMode: .common)
    }
}
