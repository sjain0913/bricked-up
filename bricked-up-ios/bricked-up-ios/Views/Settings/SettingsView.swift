import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chips: [NFCChip]

    var body: some View {
        NavigationStack {
            List {
                Section("NFC Chips") {
                    ForEach(chips) { chip in
                        HStack {
                            Image(systemName: "wave.3.right")
                            VStack(alignment: .leading) {
                                Text(chip.name)
                                    .font(.headline)
                                Text(chip.tagIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Registered \(chip.dateRegistered, style: .date)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteChips)

                    NavigationLink("Register New Chip") {
                        NFCRegistrationView()
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func deleteChips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(chips[index])
        }
        try? modelContext.save()
    }
}
