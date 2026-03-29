import Foundation
import SwiftData

@Model
final class ModeSchedule {
    @Attribute(.unique) var id: UUID
    var modeId: UUID
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    /// Days of week: 1 = Sunday, 7 = Saturday
    var activeDays: [Int]
    var isEnabled: Bool

    init(
        modeId: UUID,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        activeDays: [Int] = [2, 3, 4, 5, 6],
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.modeId = modeId
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.activeDays = activeDays
        self.isEnabled = isEnabled
    }
}
