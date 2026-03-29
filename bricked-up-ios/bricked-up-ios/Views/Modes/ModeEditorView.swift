import SwiftUI
import SwiftData
import FamilyControls

struct ModeEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var iconName: String
    @State private var activitySelection: FamilyActivitySelection
    @State private var isPickerPresented = false

    private var existingMode: BlockingMode?

    init(mode: BlockingMode? = nil) {
        self.existingMode = mode
        _name = State(initialValue: mode?.name ?? "")
        _iconName = State(initialValue: mode?.iconName ?? "lock.fill")
        _activitySelection = State(initialValue: mode?.activitySelection ?? FamilyActivitySelection())
    }

    private let icons = [
        "lock.fill", "moon.fill", "book.fill", "briefcase.fill",
        "bed.double.fill", "figure.run", "graduationcap.fill",
        "fork.knife", "gamecontroller.fill", "paintbrush.fill"
    ]

    var body: some View {
        Form {
            Section("Mode Name") {
                TextField("e.g. Work, Sleep, Study", text: $name)
            }

            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(iconName == icon ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(iconName == icon ? Color.accentColor : .clear, lineWidth: 2)
                            )
                            .onTapGesture { iconName = icon }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    isPickerPresented = true
                } label: {
                    HStack {
                        Text("Select Apps to Block")
                        Spacer()
                        Text(appsSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $activitySelection)
            } header: {
                Text("Apps to Block")
            } footer: {
                Text("Choose which apps to block when this mode is active.")
            }

            Section {
                Button {
                    isPickerPresented = true
                } label: {
                    HStack {
                        Text("Select Websites to Block")
                        Spacer()
                        Text(websitesSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $activitySelection)
            } header: {
                Text("Websites to Block")
            } footer: {
                Text("Use the Websites tab in the picker to search and select specific sites to block in Safari.")
            }
        }
        .navigationTitle(existingMode == nil ? "New Mode" : "Edit Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }

    private var appsSummary: String {
        let apps = activitySelection.applicationTokens.count
        let categories = activitySelection.categoryTokens.count
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) apps") }
        if categories > 0 { parts.append("\(categories) categories") }
        return parts.isEmpty ? "None" : parts.joined(separator: ", ")
    }

    private var websitesSummary: String {
        let domains = activitySelection.webDomainTokens.count
        return domains > 0 ? "\(domains) websites" : "None"
    }

    private func save() {
        if let mode = existingMode {
            mode.name = name
            mode.iconName = iconName
            mode.activitySelection = activitySelection
            mode.syncToSharedDefaults()
        } else {
            let mode = BlockingMode(name: name, iconName: iconName)
            mode.activitySelection = activitySelection
            modelContext.insert(mode)
            mode.syncToSharedDefaults()
        }
        try? modelContext.save()
    }
}
