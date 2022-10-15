import Cocoa
import UserNotifications

enum ClockStatus {
    case Idle
    case Running
    case Paused
}

func formatNumber (number: Int) -> String {
    if number < 10 {
        return "0" + String(number)
    } else {
        return String(number)
    }
}

func formatAttrTitle(title: String) -> NSAttributedString {
    let font = NSFont.monospacedSystemFont(ofSize: 12, weight: NSFont.Weight.light)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedTitle = NSAttributedString(string: title, attributes: attributes)
    return attributedTitle
}

func formatClockTime (timeInSeconds: TimeInterval) -> String {
    let minutes = Int(timeInSeconds / 60)
    let seconds = Int(timeInSeconds) - minutes * 60
    return formatNumber(number: minutes) + ":" + formatNumber(number: seconds)
}

func formatClock (timeInSeconds: TimeInterval) -> NSAttributedString {
    let title = formatClockTime(timeInSeconds: timeInSeconds)
    return formatAttrTitle(title: title)
}

let twentyMinutes: TimeInterval = 20 * 60

class AppDelegate: NSObject, NSApplicationDelegate {
    private var clockTimer: Timer?
    private var clockStatus: ClockStatus! = .Idle
    private var remainingTime: TimeInterval = 0
    private var statusItem: NSStatusItem!
    private var statusItemMenu: NSMenu!
    private var isNotificationsAllowed: Bool = false
    private var defaultTimerInterval: TimeInterval = twentyMinutes
    private var notificationCenter: UNUserNotificationCenter!
    
    func createClockTimer() -> Timer {
        return Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateClock),
            userInfo: nil,
            repeats: true)
    }
    
    func renderClock() {
        if let button = statusItem.button {
            button.attributedTitle = formatClock(timeInSeconds: remainingTime)
        }
    }
    
    @objc func updateClock() {
        if clockStatus == .Running {
            remainingTime -= 1
            renderClock()

            if remainingTime == 0 {
                clockStatus = .Idle
                clockTimer?.invalidate()
                sendNotification()
            }
        }
    }
    
    @objc func didTapClock(_ button: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        switch event.type {
        case .leftMouseUp:
            switch clockStatus {
            case .Idle, .none:
                remainingTime = defaultTimerInterval
                clockStatus = .Running
                clockTimer = createClockTimer()
                renderClock()
            case .Running:
                clockStatus = .Paused
                clockTimer?.invalidate()
            case .Paused:
                clockStatus = .Running
                clockTimer = createClockTimer()
            }
        case .rightMouseUp:
            statusItem.popUpMenu(statusItemMenu)
        default:
            print("none")
        }
    }
    
    @objc func didTapClear() {
        remainingTime = 0
        clockStatus = .Idle
        clockTimer?.invalidate()
        renderClock()
    }
    
    func setupSystemTray() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(didTapClock(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // button.image = NSImage(systemSymbolName: "1.circle", accessibilityDescription: "1")
            renderClock()
        }
    }
    
    func setupMenu() {
        let menu = NSMenu()
        let one = NSMenuItem(title: "Clear", action: #selector(didTapClear), keyEquivalent: "space")
        menu.addItem(one)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItemMenu = menu
    }
    
    func setupNotifications() {
        notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                // Handle the error here.
            }
         
            self.isNotificationsAllowed = granted
        }
    }
    
    func sendNotification() {
        if !isNotificationsAllowed {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Totodoro!"
        content.body = "You've finished a cycle of focus"

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: uuidString,
            content: content,
            trigger: nil)

        // Schedule the request with the system.
        notificationCenter.add(request) { (error) in
            print("help")
            if error != nil {
                // Handle any errors.
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupSystemTray()
        setupMenu()
        setupNotifications()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

