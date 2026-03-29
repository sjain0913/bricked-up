import SwiftUI
import SwiftData

struct ScheduleEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BlockingMode.sortOrder) private var modes: [BlockingMode]

    @State private var selectedModeId: UUID?
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var activeDays: Set<Int>

    private var existingSchedule: ModeSchedule?

    private let dayOptions: [(id: Int, label: String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]

    init(schedule: ModeSchedule? = nil) {
        self.existingSchedule = schedule

        let calendar = Calendar.current
        if let schedule {
            _selectedModeId = State(initialValue: schedule.modeId)
            _startTime = State(initialValue: calendar.date(from: DateComponents(hour: schedule.startHour, minute: schedule.startMinute)) ?? Date())
            _endTime = State(initialValue: calendar.date(from: DateComponents(hour: schedule.endHour, minute: schedule.endMinute)) ?? Date())
            _activeDays = State(initialValue: Set(schedule.activeDays))
        } else {
            _selectedModeId = State(initialValue: nil)
            _startTime = State(initialValue: calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date())
            _endTime = State(initialValue: calendar.date(from: DateComponents(hour: 17, minute: 0)) ?? Date())
            _activeDays = State(initialValue: [2, 3, 4, 5, 6]) // Mon-Fri
        }
    }

    var body: some View {
        Form {
            Section("Mode") {
                if modes.isEmpty {
                    Text("Create a mode first")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Mode", selection: $selectedModeId) {
                        Text("Select a mode").tag(nil as UUID?)
                        ForEach(modes) { mode in
                            Label(mode.name, systemImage: mode.iconName)
                                .tag(mode.id as UUID?)
                        }
                    }
                }
            }

            Section("Time") {
                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
            }

            Section("Days") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(dayOptions, id: \.id) { day in
                        Button {
                            if activeDays.contains(day.id) {
                                activeDays.remove(day.id)
                            } else {
                                activeDays.insert(day.id)
                            }
                        } label: {
                            Text(day.label)
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(activeDays.contains(day.id) ? Color.accentColor : Color(.systemGray5))
                                .foregroundStyle(activeDays.contains(day.id) ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(existingSchedule == nil ? "New Schedule" : "Edit Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(selectedModeId == nil || activeDays.isEmpty)
            }
        }
    }

    private func save() {
        guard let modeId = selectedModeId else { return }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        // Ensure the mode's selection data is in shared defaults so the extension can read it
        let modeDescriptor = FetchDescriptor<BlockingMode>(predicate: #Predicate { $0.id == modeId })
        if let mode = try? modelContext.fetch(modeDescriptor).first {
            mode.syncToSharedDefaults()
        }

        if let schedule = existingSchedule {
            ScheduleService.shared.unregisterSchedule(schedule)
            schedule.modeId = modeId
            schedule.startHour = startComponents.hour ?? 9
            schedule.startMinute = startComponents.minute ?? 0
            schedule.endHour = endComponents.hour ?? 17
            schedule.endMinute = endComponents.minute ?? 0
            schedule.activeDays = Array(activeDays)
            schedule.isEnabled = true
            ScheduleService.shared.registerSchedule(schedule)
        } else {
            let schedule = ModeSchedule(
                modeId: modeId,
                startHour: startComponents.hour ?? 9,
                startMinute: startComponents.minute ?? 0,
                endHour: endComponents.hour ?? 17,
                endMinute: endComponents.minute ?? 0,
                activeDays: Array(activeDays)
            )
            modelContext.insert(schedule)
            ScheduleService.shared.registerSchedule(schedule)
        }
        try? modelContext.save()
    }
}
