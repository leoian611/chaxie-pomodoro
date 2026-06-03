import Cocoa
import UserNotifications

enum Phase {
    case focus
    case rest
}

final class AppController: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    private var statusItem: NSStatusItem!
    private var headerItem: NSMenuItem!
    private var toggleItem: NSMenuItem!
    private var timer: Timer?

    private var phase: Phase = .focus
    private var running = false
    private var remaining = 0

    private let focusOptions = [15, 25, 30, 45, 50]
    private let restOptions  = [5, 10, 15, 20]

    // MARK: - 持久化的时长（秒）
    private var focusDuration: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "focusDuration")
            return v > 0 ? v : 25 * 60
        }
        set { UserDefaults.standard.set(newValue, forKey: "focusDuration") }
    }
    private var restDuration: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "restDuration")
            return v > 0 ? v : 5 * 60
        }
        set { UserDefaults.standard.set(newValue, forKey: "restDuration") }
    }

    // MARK: - 生命周期
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // 不进 Dock，只待在菜单栏

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert]) { _, _ in }  // 只要横幅，不要声音权限

        phase = .focus
        remaining = focusDuration
        running = false

        buildMenu()
        updateUI()
    }

    // MARK: - 菜单
    private func buildMenu() {
        let menu = NSMenu()

        headerItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(.separator())

        toggleItem = NSMenuItem(title: "开始", action: #selector(toggleRun), keyEquivalent: "s")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let skip = NSMenuItem(title: "跳到下一阶段", action: #selector(skipPhase), keyEquivalent: "n")
        skip.target = self
        menu.addItem(skip)

        let reset = NSMenuItem(title: "重置当前阶段", action: #selector(resetPhase), keyEquivalent: "r")
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())

        // 专注时长
        let focusItem = NSMenuItem(title: "专注时长", action: nil, keyEquivalent: "")
        let focusMenu = NSMenu()
        for m in focusOptions {
            let it = NSMenuItem(title: "\(m) 分钟", action: #selector(setFocus(_:)), keyEquivalent: "")
            it.target = self
            it.tag = m
            it.state = (m * 60 == focusDuration) ? .on : .off
            focusMenu.addItem(it)
        }
        let fc = NSMenuItem(title: "自定义…", action: #selector(customFocus), keyEquivalent: "")
        fc.target = self
        focusMenu.addItem(fc)
        focusItem.submenu = focusMenu
        menu.addItem(focusItem)

        // 休息时长
        let restItem = NSMenuItem(title: "休息时长", action: nil, keyEquivalent: "")
        let restMenu = NSMenu()
        for m in restOptions {
            let it = NSMenuItem(title: "\(m) 分钟", action: #selector(setRest(_:)), keyEquivalent: "")
            it.target = self
            it.tag = m
            it.state = (m * 60 == restDuration) ? .on : .off
            restMenu.addItem(it)
        }
        let rc = NSMenuItem(title: "自定义…", action: #selector(customRest), keyEquivalent: "")
        rc.target = self
        restMenu.addItem(rc)
        restItem.submenu = restMenu
        menu.addItem(restItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - 计时器
    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)   // 菜单打开时也继续走
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func tick() {
        guard running else { return }
        remaining -= 1
        if remaining <= 0 {
            advancePhase(auto: true)
        } else {
            updateUI()
        }
    }

    // MARK: - 操作
    @objc private func toggleRun() {
        running.toggle()
        running ? startTimer() : stopTimer()
        updateUI()
    }

    @objc private func skipPhase() { advancePhase(auto: false) }

    @objc private func resetPhase() {
        remaining = (phase == .focus) ? focusDuration : restDuration
        updateUI()
    }

    @objc private func setFocus(_ sender: NSMenuItem) {
        focusDuration = sender.tag * 60
        if phase == .focus && !running { remaining = focusDuration }
        buildMenu(); updateUI()
    }

    @objc private func setRest(_ sender: NSMenuItem) {
        restDuration = sender.tag * 60
        if phase == .rest && !running { remaining = restDuration }
        buildMenu(); updateUI()
    }

    @objc private func customFocus() {
        if let s = askMinutes(title: "设置专注时长", current: focusDuration) {
            focusDuration = s
            if phase == .focus && !running { remaining = focusDuration }
            buildMenu(); updateUI()
        }
    }

    @objc private func customRest() {
        if let s = askMinutes(title: "设置休息时长", current: restDuration) {
            restDuration = s
            if phase == .rest && !running { remaining = restDuration }
            buildMenu(); updateUI()
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - 阶段切换
    private func advancePhase(auto: Bool) {
        if phase == .focus {
            if auto { notify(title: "专注结束", body: "去喝口茶 🍵") }
            phase = .rest
            remaining = restDuration
        } else {
            if auto { notify(title: "茶歇结束", body: "继续专注 🍃") }
            phase = .focus
            remaining = focusDuration
        }
        if running && timer == nil { startTimer() }
        buildMenu()
        updateUI()
    }

    // MARK: - 界面刷新
    private func updateUI() {
        let icon = (phase == .focus) ? "🍃" : "🍵"
        statusItem.button?.title = "\(icon) \(fmt(remaining))"

        let name = (phase == .focus) ? "专注" : "茶歇"
        let suffix = running ? "" : "（已暂停）"
        headerItem?.title = "\(name) · \(fmt(remaining))\(suffix)"
        toggleItem?.title = running ? "暂停" : "开始"
    }

    private func fmt(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - 通知（静音）
    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil   // 关键：不出声，避免被吓到
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])   // 右上角横幅，无声
    }

    private func askMinutes(title: String, current: Int) -> Int? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = "输入分钟数（1–180）"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.stringValue = String(current / 60)
        alert.accessoryView = field
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        NSApp.activate(ignoringOtherApps: true)
        alert.window.makeKeyAndOrderFront(nil)
        let resp = alert.runModal()
        if resp == .alertFirstButtonReturn,
           let m = Int(field.stringValue.trimmingCharacters(in: .whitespaces)),
           m >= 1, m <= 180 {
            return m * 60
        }
        return nil
    }
}

let app = NSApplication.shared
let controller = AppController()
app.delegate = controller
app.run()
