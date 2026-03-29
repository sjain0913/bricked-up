import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chips: [NFCChip]

    @State private var brickingService = BrickingService()
    @State private var isProgramming = false
    @State private var programSuccess = false
    @State private var programError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                } header: {
                    Text("NFC Chips")
                }

                Section {
                    Button {
                        Task { await programChip() }
                    } label: {
                        HStack {
                            Label("Program Chip for Background Tap", systemImage: "antenna.radiowaves.left.and.right")
                            Spacer()
                            if isProgramming {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isProgramming)

                    if programSuccess {
                        Label("Chip programmed! Tap it anytime to brick/unbrick.", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if let err = programError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Background NFC")
                } footer: {
                    Text("Program your chip once, then tap it directly — iOS will open the app and toggle automatically, no button press needed.")
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

    private func programChip() async {
        isProgramming = true
        programSuccess = false
        programError = nil
        do {
            try await brickingService.programChip()
            programSuccess = true
        } catch NFCError.cancelled {
            // user cancelled, no message needed
        } catch {
            programError = error.localizedDescription
        }
        isProgramming = false
    }

    private func deleteChips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(chips[index])
        }
        try? modelContext.save()
    }
}
