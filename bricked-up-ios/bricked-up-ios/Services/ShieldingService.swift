import Foundation
import ManagedSettings
import FamilyControls

final class ShieldingService {
    static let shared = ShieldingService()

    private init() {}

    func applyShield(for mode: BlockingMode) {
        let store = ManagedSettingsStore(named: storeName(for: mode))
        let selection = mode.activitySelection

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)

        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
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
    }

    static func removeShield(modeId: String) {
        let store = ManagedSettingsStore(named: .init(rawValue: "mode-\(modeId)"))
        store.clearAllSettings()
    }
}
