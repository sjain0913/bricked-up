//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by Saumya Jain on 3/28/26.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let appGroupID = "group.com.bricked-up-ios"

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Activity name format: "schedule-{scheduleId}"
        let scheduleId = activity.rawValue.replacingOccurrences(of: "schedule-", with: "")
        guard let modeId = sharedDefaults.string(forKey: "schedule-\(scheduleId)-modeId") else { return }

        // Apply shields for this mode
        applyShield(modeId: modeId)

        // Update shared state
        sharedDefaults.set("locked", forKey: "brickState")
        sharedDefaults.set(modeId, forKey: "activeModeId")
        sharedDefaults.set(Date(), forKey: "sessionStartTime")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let scheduleId = activity.rawValue.replacingOccurrences(of: "schedule-", with: "")
        guard let modeId = sharedDefaults.string(forKey: "schedule-\(scheduleId)-modeId") else { return }

        // Only remove if still locked by this schedule
        let currentState = sharedDefaults.string(forKey: "brickState")
        guard currentState == "locked" else { return }

        removeShield(modeId: modeId)

        sharedDefaults.set("unlocked", forKey: "brickState")
        sharedDefaults.removeObject(forKey: "activeModeId")
        sharedDefaults.removeObject(forKey: "sessionStartTime")
    }

    private func applyShield(modeId: String) {
        guard let data = sharedDefaults.data(forKey: "mode-\(modeId)-selection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else { return }

        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        // Actual website blocking via domain strings
        let blockedDomains = sharedDefaults.stringArray(forKey: "mode-\(modeId)-domains") ?? []
        let filtered = blockedDomains.filter { !$0.isEmpty }
        if !filtered.isEmpty {
            let webDomains = Set(filtered.map { WebDomain(domain: $0) })
            store.webContent.blockedByFilter = .specific(webDomains)
        }
    }

    private func removeShield(modeId: String) {
        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))
        store.clearAllSettings()
    }
}
