import Foundation

enum AppConstants {
    static let appGroupID = "group.com.bricked-up-ios"

    static let sharedDefaults: UserDefaults = {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }()

    static let sharedContainerURL: URL = {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url
        }
        // Fallback for when App Groups entitlement isn't available (e.g. Personal Team)
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }()
}
