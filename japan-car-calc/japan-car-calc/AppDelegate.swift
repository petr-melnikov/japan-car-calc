import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var window: NSWindow?
    let calculatorModel = CalculatorModel()
    var lastFrame: NSRect?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Активируем приложение для работы из menu bar
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "car.fill", accessibilityDescription: "Калькулятор авто") {
                image.isTemplate = true
                button.image = image
            }
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusItemClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Правый клик - показываем меню
            showMenu()
        } else {
            // Левый клик - показываем/скрываем окно
            toggleWindow()
        }
    }
    
    func showMenu() {
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Выйти", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        
        // Убираем меню после показа
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    func toggleWindow() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 240, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false)
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.title = "Калькулятор авто"
            window.contentView = NSHostingView(rootView: ContentView(model: calculatorModel))
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            
            // Позиционируем окно под иконкой в menu bar
            if let button = statusItem.button, let buttonWindow = button.window {
                let buttonFrame = buttonWindow.convertToScreen(button.frame)
                let windowX = buttonFrame.midX - window.frame.width / 2
                let windowY = buttonFrame.minY - window.frame.height - 5
                window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
            } else {
                window.center()
            }
            
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            self.window = window
            print("Окно создано и показано")
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self, weak window] _ in
                if let frame = window?.frame { self?.lastFrame = frame }
                self?.window = nil
                print("Окно закрыто")
            }
        } else {
            if let window = window {
                lastFrame = window.frame
            }
            window?.close()
            print("Окно закрыто пользователем")
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
