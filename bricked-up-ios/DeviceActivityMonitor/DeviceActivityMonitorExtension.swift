import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import UserNotifications

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let defaults = UserDefaults(suiteName: "group.com.bricked-up-ios") ?? .standard

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let key = activity.rawValue
        guard let modeId = defaults.string(forKey: "\(key)-modeId") else { return }

        // Check if today is one of the scheduled days (1=Sun, 7=Sat)
        let activeDays = defaults.array(forKey: "\(key)-activeDays") as? [Int] ?? []
        if !activeDays.isEmpty {
            let todayWeekday = Calendar.current.component(.weekday, from: Date())
            guard activeDays.contains(todayWeekday) else { return }
        }

        // User manually unbricked during this window — respect their choice until the window ends
        if defaults.bool(forKey: "scheduledManualOverride") { return }

        applyShield(modeId: modeId)

        defaults.set("locked", forKey: "brickState")
        defaults.set(modeId, forKey: "activeModeId")
        defaults.set(Date(), forKey: "sessionStartTime")
        defaults.set(true, forKey: "wasScheduledLock")

        let modeName = defaults.string(forKey: "mode-\(modeId)-name") ?? "Focus"
        sendNotification(
            id: "brick-\(key)",
            title: "Time to get BRICKED 🍆",
            body: "\(modeName) mode is now active. Stay focused."
        )
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let key = activity.rawValue
        guard let modeId = defaults.string(forKey: "\(key)-modeId") else { return }

        // Only remove shields if this schedule was the one that locked it
        guard defaults.string(forKey: "brickState") == "locked",
              defaults.string(forKey: "activeModeId") == modeId else { return }

        removeShield(modeId: modeId)

        defaults.set("unlocked", forKey: "brickState")
        defaults.removeObject(forKey: "activeModeId")
        defaults.removeObject(forKey: "sessionStartTime")
        // Window is over — clear override flags so next window bricks normally
        defaults.removeObject(forKey: "wasScheduledLock")
        defaults.removeObject(forKey: "scheduledManualOverride")

        let modeName = defaults.string(forKey: "mode-\(modeId)-name") ?? "Focus"
        sendNotification(
            id: "unbrick-\(key)",
            title: "Time to get UNBRICKED 🍆",
            body: "\(modeName) mode has ended. Welcome back."
        )
    }

    private func applyShield(modeId: String) {
        guard let data = defaults.data(forKey: "mode-\(modeId)-selection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else { return }

        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        let blockedDomains = defaults.stringArray(forKey: "mode-\(modeId)-domains") ?? []
        let filtered = blockedDomains.filter { !$0.isEmpty }
        if !filtered.isEmpty {
            let webDomains = Set(filtered.map { WebDomain(domain: $0) })
            store.webContent.blockedByFilter = .specific(webDomains)
        }
    }

    private func sendNotification(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func removeShield(modeId: String) {
        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))
        store.clearAllSettings()
    }
}
