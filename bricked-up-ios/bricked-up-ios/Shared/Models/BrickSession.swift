import Foundation
import SwiftData

@Model
final class BrickSession {
    @Attribute(.unique) var id: UUID
    var modeId: UUID?
    var modeName: String
    var startTime: Date
    var endTime: Date?
    var wasScheduled: Bool

    init(modeId: UUID?, modeName: String, wasScheduled: Bool = false) {
        self.id = UUID()
        self.modeId = modeId
        self.modeName = modeName
        self.startTime = Date()
        self.endTime = nil
        self.wasScheduled = wasScheduled
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isActive: Bool {
        endTime == nil
    }
}
