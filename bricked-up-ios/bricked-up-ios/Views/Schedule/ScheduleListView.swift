import SwiftUI
import SwiftData

struct ScheduleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ModeSchedule.startHour) private var schedules: [ModeSchedule]
    @Query private var modes: [BlockingMode]

    var body: some View {
        NavigationStack {
            List {
                ForEach(schedules) { schedule in
                    NavigationLink {
                        ScheduleEditorView(schedule: schedule)
                    } label: {
                        ScheduleRow(
                            schedule: schedule,
                            modeName: modeName(for: schedule.modeId),
                            onToggle: { enabled in
                                schedule.isEnabled = enabled
                                if enabled {
                                    ScheduleService.shared.registerSchedule(schedule)
                                } else {
                                    ScheduleService.shared.unregisterSchedule(schedule)
                                }
                                try? modelContext.save()
                            }
                        )
                    }
                }
                .onDelete(perform: deleteSchedules)
            }
            .navigationTitle("Schedules")
            .toolbar {
                NavigationLink {
                    ScheduleEditorView()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .overlay {
                if schedules.isEmpty {
                    ContentUnavailableView(
                        "No Schedules",
                        systemImage: "calendar",
                        description: Text("Schedule modes to activate automatically at set times.")
                    )
                }
            }
        }
    }

    private func modeName(for modeId: UUID) -> String {
        modes.first { $0.id == modeId }?.name ?? "Unknown"
    }

    private func deleteSchedules(at offsets: IndexSet) {
        for index in offsets {
            let schedule = schedules[index]
            ScheduleService.shared.unregisterSchedule(schedule)
            modelContext.delete(schedule)
        }
        try? modelContext.save()
    }
}

struct ScheduleRow: View {
    @Bindable var schedule: ModeSchedule
    let modeName: String
    var onToggle: (Bool) -> Void

    private let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(modeName)
                    .font(.headline)
                Text(timeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(daysString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
    }

    private var timeString: String {
        let start = formatTime(hour: schedule.startHour, minute: schedule.startMinute)
        let end = formatTime(hour: schedule.endHour, minute: schedule.endMinute)
        return "\(start) - \(end)"
    }

    private var daysString: String {
        schedule.activeDays.sorted().compactMap { day in
            guard day >= 1 && day <= 7 else { return nil }
            return dayLabels[day]
        }.joined(separator: ", ")
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, period)
    }
}
