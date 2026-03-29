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
    @State private var blockedDomains: [String]
    @State private var newDomain = ""

    private var existingMode: BlockingMode?

    init(mode: BlockingMode? = nil) {
        self.existingMode = mode
        _name = State(initialValue: mode?.name ?? "")
        _iconName = State(initialValue: mode?.iconName ?? "lock.fill")
        _activitySelection = State(initialValue: mode?.activitySelection ?? FamilyActivitySelection())
        _blockedDomains = State(initialValue: mode?.customBlockedDomains ?? [])
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
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $activitySelection)
            } header: {
                Text("Apps to Block")
            } footer: {
                Text("Select apps and categories to block when this mode is active.")
            }

            Section {
                HStack {
                    TextField("e.g. x.com, reddit.com", text: $newDomain)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Button {
                        addDomain()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ForEach(blockedDomains, id: \.self) { domain in
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                        Text(domain)
                    }
                }
                .onDelete { offsets in
                    blockedDomains.remove(atOffsets: offsets)
                }
            } header: {
                Text("Websites to Block")
            } footer: {
                Text("Enter domain names to block in Safari. For example: x.com, reddit.com, instagram.com")
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

    private func addDomain() {
        var domain = newDomain.trimmingCharacters(in: .whitespaces).lowercased()
        // Strip protocol prefixes
        for prefix in ["https://", "http://", "www."] {
            if domain.hasPrefix(prefix) {
                domain = String(domain.dropFirst(prefix.count))
            }
        }
        // Strip trailing slash
        if domain.hasSuffix("/") {
            domain = String(domain.dropLast())
        }
        guard !domain.isEmpty, !blockedDomains.contains(domain) else { return }
        blockedDomains.append(domain)
        newDomain = ""
    }

    private func save() {
        if let mode = existingMode {
            mode.name = name
            mode.iconName = iconName
            mode.activitySelection = activitySelection
            mode.customBlockedDomains = blockedDomains
            mode.updateCachedCounts()
            mode.syncToSharedDefaults()
        } else {
            let mode = BlockingMode(name: name, iconName: iconName, customBlockedDomains: blockedDomains)
            mode.activitySelection = activitySelection
            mode.updateCachedCounts()
            modelContext.insert(mode)
            mode.syncToSharedDefaults()
        }
        try? modelContext.save()
    }
}
