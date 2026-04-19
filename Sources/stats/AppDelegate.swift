import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let cpuMonitor = CPUUsage()
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "CPU: --%"
        }
        
        setupMenu()
        startMonitoring()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
    }

    func setupMenu() {
        let menu = NSMenu()
        
        let aboutItem = NSMenuItem(title: "About CPU Monitor", action: #selector(about), keyEquivalent: "")
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }

    @objc func about() {
        let alert = NSAlert()
        alert.messageText = "CPU Monitor"
        alert.informativeText = "A simple native macOS CPU monitor written in Swift."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func startMonitoring() {
        // Initial sample
        _ = cpuMonitor.getUsage()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let usage = self.cpuMonitor.getUsage() {
                DispatchQueue.main.async {
                    if let button = self.statusItem?.button {
                        button.title = String(format: "CPU: %.1f%%", usage)
                    }
                }
            }
        }
        timer?.tolerance = 0.5
        RunLoop.current.add(timer!, forMode: .common)
    }
}
