import Foundation
import ManagedSettings
import FamilyControls

final class ShieldingService {
    static let shared = ShieldingService()

    private init() {}

    func applyShield(for mode: BlockingMode) {
        let store = ManagedSettingsStore(named: storeName(for: mode))
        let selection = mode.activitySelection

        // App shielding
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)

        // Web domain shielding (visual overlay from picker tokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        // Actual website blocking via WebContentSettings (uses domain strings)
        let blockedDomains = mode.customBlockedDomains.filter { !$0.isEmpty }
        if !blockedDomains.isEmpty {
            let webDomains = Set(blockedDomains.map { WebDomain(domain: $0) })
            store.webContent.blockedByFilter = .specific(webDomains)
        }
    }

    func removeShield(for mode: BlockingMode) {
        let store = ManagedSettingsStore(named: storeName(for: mode))
        store.clearAllSettings()
    }

    func removeAllShields() {
        ManagedSettingsStore().clearAllSettings()
    }

    private func storeName(for mode: BlockingMode) -> ManagedSettingsStore.Name {
        ManagedSettingsStore.Name(rawValue: "mode-\(mode.id.uuidString)")
    }

    // MARK: - Extension-friendly methods (use from DeviceActivityMonitor)

    static func applyShield(modeId: String) {
        let defaults = AppConstants.sharedDefaults
        guard let data = defaults.data(forKey: "mode-\(modeId)-selection") else { return }
        guard let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else { return }

        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        // Actual website blocking via domain strings
        let blockedDomains = defaults.stringArray(forKey: "mode-\(modeId)-domains") ?? []
        let filtered = blockedDomains.filter { !$0.isEmpty }
        if !filtered.isEmpty {
            let webDomains = Set(filtered.map { WebDomain(domain: $0) })
            store.webContent.blockedByFilter = .specific(webDomains)
        }
    }

    static func removeShield(modeId: String) {
        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))
        store.clearAllSettings()
    }
}
