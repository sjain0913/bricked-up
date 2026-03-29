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

    private static let plistDecoder = PropertyListDecoder()
    private static let plistEncoder = PropertyListEncoder()

    var activitySelection: FamilyActivitySelection {
        get {
            guard let data = selectedAppsData else { return FamilyActivitySelection() }
            return (try? Self.plistDecoder.decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
        }
        set {
            selectedAppsData = try? Self.plistEncoder.encode(newValue)
        }
    }

    /// Cached token counts — updated on save to avoid decoding in list views.
    var appCount: Int = 0
    var categoryCount: Int = 0
    var webDomainCount: Int = 0

    /// Call after modifying activitySelection to update cached counts.
    func updateCachedCounts() {
        let sel = activitySelection
        appCount = sel.applicationTokens.count
        categoryCount = sel.categoryTokens.count
        webDomainCount = sel.webDomainTokens.count
    }

    /// Syncs this mode's selection data to App Group UserDefaults for extension access.
    func syncToSharedDefaults() {
        let defaults = AppConstants.sharedDefaults
        defaults.set(selectedAppsData, forKey: "mode-\(id.uuidString)-selection")
        defaults.set(customBlockedDomains, forKey: "mode-\(id.uuidString)-domains")
        defaults.set(name, forKey: "mode-\(id.uuidString)-name")
    }
}
