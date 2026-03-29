import SwiftUI
import SwiftData

struct NFCRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var chips: [NFCChip]

    @State private var brickingService = BrickingService()
    @State private var chipName = "My Brick"
    @State private var registeredChip: NFCChip?
    @State private var errorMessage: String?
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Register Your NFC Chip")
                .font(.title2.bold())

            Text("Hold your phone near your NFC chip to register it as your Brick.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField("Chip Name", text: $chipName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 48)

            Button {
                isScanning = true
                Task {
                    do {
                        registeredChip = try await brickingService.registerChip(
                            name: chipName,
                            modelContext: modelContext
                        )
                        errorMessage = nil
                    } catch NFCError.cancelled {
                        // User cancelled
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isScanning = false
                }
            } label: {
                Label("Scan NFC Chip", systemImage: "wave.3.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isScanning)
            .padding(.horizontal)

            if let chip = registeredChip {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    Text("Chip registered: \(chip.name)")
                        .font(.headline)
                    Text("ID: \(chip.tagIdentifier)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Show existing chips
            if !chips.isEmpty {
                Divider().padding(.horizontal)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Registered Chips")
                        .font(.headline)
                    ForEach(chips) { chip in
                        HStack {
                            Image(systemName: "wave.3.right")
                            VStack(alignment: .leading) {
                                Text(chip.name).font(.subheadline)
                                Text(chip.tagIdentifier).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .navigationTitle("Register Chip")
        .navigationBarTitleDisplayMode(.inline)
    }
}
