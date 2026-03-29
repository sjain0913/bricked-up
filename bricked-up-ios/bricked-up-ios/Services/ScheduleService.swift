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

        // Store schedule-to-mode mapping in shared defaults for the extension
        let defaults = AppConstants.sharedDefaults
        defaults.set(schedule.modeId.uuidString, forKey: "schedule-\(schedule.id.uuidString)-modeId")

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
        defaults.removeObject(forKey: "schedule-\(schedule.id.uuidString)-modeId")
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
