import Foundation
import DeviceActivity
import SwiftData

final class ScheduleService {
    static let shared = ScheduleService()
    private let center = DeviceActivityCenter()

    private init() {}

    func registerSchedule(_ schedule: ModeSchedule) {
        let activityName = DeviceActivityName(rawValue: "schedule-\(schedule.id.uuidString)")

        let deviceSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: schedule.startHour, minute: schedule.startMinute),
            intervalEnd: DateComponents(hour: schedule.endHour, minute: schedule.endMinute),
            repeats: true,
            warningTime: nil
        )

        // Store all data the extension needs to apply the schedule correctly
        let defaults = AppConstants.sharedDefaults
        let key = "schedule-\(schedule.id.uuidString)"
        defaults.set(schedule.modeId.uuidString, forKey: "\(key)-modeId")
        defaults.set(schedule.activeDays, forKey: "\(key)-activeDays")

        do {
            try center.startMonitoring(activityName, during: deviceSchedule)
        } catch {
            print("Failed to start monitoring schedule: \(error)")
        }
    }

    func unregisterSchedule(_ schedule: ModeSchedule) {
        let activityName = DeviceActivityName(rawValue: "schedule-\(schedule.id.uuidString)")
        center.stopMonitoring([activityName])

        let defaults = AppConstants.sharedDefaults
        let key = "schedule-\(schedule.id.uuidString)"
        defaults.removeObject(forKey: "\(key)-modeId")
        defaults.removeObject(forKey: "\(key)-activeDays")
    }

    func syncAllSchedules(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ModeSchedule>(
            predicate: #Predicate { $0.isEnabled }
        )
        guard let schedules = try? modelContext.fetch(descriptor) else { return }

        // Stop all existing monitoring
        center.stopMonitoring()

        // Re-register all enabled schedules
        for schedule in schedules {
            registerSchedule(schedule)
        }
    }
}
