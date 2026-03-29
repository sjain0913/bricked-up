import Foundation
import SwiftData
import FamilyControls

@Model
final class BlockingMode {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var selectedAppsData: Data?
    var customBlockedDomains: [String]
    var isActive: Bool
    var createdAt: Date
    var sortOrder: Int

    init(
        name: String,
        iconName: String = "lock.fill",
        customBlockedDomains: [String] = [],
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.selectedAppsData = nil
        self.customBlockedDomains = customBlockedDomains
        self.isActive = false
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    var activitySelection: FamilyActivitySelection {
        get {
            guard let data = selectedAppsData else { return FamilyActivitySelection() }
            do {
                return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
            } catch {
                // Fallback: try JSON in case older data was stored that way
                return (try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
            }
        }
        set {
            do {
                selectedAppsData = try PropertyListEncoder().encode(newValue)
            } catch {
                print("Failed to encode FamilyActivitySelection: \(error)")
                selectedAppsData = nil
            }
        }
    }

    /// Syncs this mode's selection data to App Group UserDefaults for extension access.
    func syncToSharedDefaults() {
        let defaults = AppConstants.sharedDefaults
        defaults.set(selectedAppsData, forKey: "mode-\(id.uuidString)-selection")
        defaults.set(customBlockedDomains, forKey: "mode-\(id.uuidString)-domains")
        defaults.set(name, forKey: "mode-\(id.uuidString)-name")
    }
}
