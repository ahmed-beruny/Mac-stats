import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let cpuMonitor = CPUUsage()
    let ramMonitor = RAMUsage()
    var timer: Timer?
    var appMemoryItem: NSMenuItem?
    var wiredMemoryItem: NSMenuItem?
    var compressedMemoryItem: NSMenuItem?

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
                        let formattedUsed = self.ramMonitor.formatBytes(ram.used)
                        ramStr = String(format: "R:%6s", (formattedUsed as NSString).utf8String!)
                        
                        // Update tooltip with breakdown
                        let appStr = self.ramMonitor.formatBytes(ram.app)
                        let wiredStr = self.ramMonitor.formatBytes(ram.wired)
                        let compressedStr = self.ramMonitor.formatBytes(ram.compressed)
                        
                        button.toolTip = """
                        Memory Usage:
                        App Memory: \(appStr)
                        Wired Memory: \(wiredStr)
                        Compressed: \(compressedStr)
                        Total Used: \(formattedUsed)
                        """
                        
                        // Update menu items
                        self.appMemoryItem?.title = "App Memory: \(appStr)"
                        self.wiredMemoryItem?.title = "Wired Memory: \(wiredStr)"
                        self.compressedMemoryItem?.title = "Compressed: \(compressedStr)"
                    }
                    
                    button.title = "\(cpuStr)\(ramStr)"
                }
            }
        }
        timer?.tolerance = 0.1
        RunLoop.current.add(timer!, forMode: .common)
    }
}

