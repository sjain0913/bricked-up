import Foundation

enum BrickState: String, Codable {
    case locked
    case unlocked
}

@Observable
final class AppState {
    static let shared = AppState()

    private let defaults = AppConstants.sharedDefaults

    private enum Keys {
        static let brickState = "brickState"
        static let activeModeId = "activeModeId"
        static let activeModeData = "activeModeData"
        static let sessionStartTime = "sessionStartTime"
        static let lastUsedModeId = "lastUsedModeId"
        static let wasScheduledLock = "wasScheduledLock"
        static let scheduledManualOverride = "scheduledManualOverride"
    }

    var currentState: BrickState {
        get {
            guard let raw = defaults.string(forKey: Keys.brickState) else { return .unlocked }
            return BrickState(rawValue: raw) ?? .unlocked
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.brickState)
        }
    }

    var activeModeId: UUID? {
        get {
            guard let string = defaults.string(forKey: Keys.activeModeId) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Keys.activeModeId)
        }
    }

    /// Serialized FamilyActivitySelection data for the active mode.
    /// Used by extensions to apply/remove shields without SwiftData access.
    var activeModeData: Data? {
        get { defaults.data(forKey: Keys.activeModeData) }
        set { defaults.set(newValue, forKey: Keys.activeModeData) }
    }

    var sessionStartTime: Date? {
        get { defaults.object(forKey: Keys.sessionStartTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.sessionStartTime) }
    }

    /// True when the current lock was triggered by a DeviceActivity schedule (not a manual NFC scan).
    var wasScheduledLock: Bool {
        get { defaults.bool(forKey: Keys.wasScheduledLock) }
        set { defaults.set(newValue, forKey: Keys.wasScheduledLock) }
    }

    /// True when the user manually unbricked during an active scheduled window.
    /// The extension checks this to avoid re-bricking until the window ends.
    var scheduledManualOverride: Bool {
        get { defaults.bool(forKey: Keys.scheduledManualOverride) }
        set { defaults.set(newValue, forKey: Keys.scheduledManualOverride) }
    }

    /// The last mode used for bricking — applied automatically on background NFC tap.
    var lastUsedModeId: UUID? {
        get {
            guard let string = defaults.string(forKey: Keys.lastUsedModeId) else { return nil }
            return UUID(uuidString: string)
        }
        set { defaults.set(newValue?.uuidString, forKey: Keys.lastUsedModeId) }
    }

    private init() {}
}
