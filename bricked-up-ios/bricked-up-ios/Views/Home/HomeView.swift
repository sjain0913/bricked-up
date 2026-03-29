import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var modes: [BlockingMode]
    @Query private var chips: [NFCChip]

    @State private var brickingService = BrickingService()
    @State private var selectedMode: BlockingMode?
    @State private var currentState: BrickState = AppState.shared.currentState
    @State private var sessionStart: Date? = AppState.shared.sessionStartTime

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // State indicator
                VStack(spacing: 12) {
                    Image(systemName: currentState == .locked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(currentState == .locked ? .red : .green)
                        .contentTransition(.symbolEffect(.replace))

                    Text(currentState == .locked ? "BRICKED" : "UNLOCKED")
                        .font(.largeTitle.bold())

                    if currentState == .locked, let start = appState.sessionStartTime {
                        Text("Since \(start, style: .relative) ago")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Mode selector
                if currentState == .unlocked {
                    if modes.isEmpty {
                        NavigationLink("Create Your First Mode") {
                            ModeEditorView()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        VStack(spacing: 8) {
                            Text("Select a mode")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(modes) { mode in
                                        ModeCard(mode: mode, isSelected: selectedMode?.id == mode.id)
                                            .onTapGesture { selectedMode = mode }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                // Action button
                if chips.isEmpty {
                    NavigationLink("Register NFC Chip First") {
                        NFCRegistrationView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button {
                        Task {
                            await brickingService.scanAndToggle(
                                mode: currentState == .locked ? nil : selectedMode,
                                modelContext: modelContext
                            )
                        }
                    } label: {
                        Label(
                            currentState == .locked ? "Tap NFC to Unbrick" : "Tap NFC to Brick",
                            systemImage: "wave.3.right"
                        )
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(currentState == .locked ? .green : .red)
                    .disabled(currentState == .unlocked && selectedMode == nil)
                    .padding(.horizontal)
                }

                if let error = brickingService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Bricked Up")
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Re-read state from shared defaults in case extension changed it
                    refreshTrigger.toggle()
                }
            }
            .id(refreshTrigger)
        }
    }
}

struct ModeCard: View {
    let mode: BlockingMode
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: mode.iconName)
                .font(.title2)
            Text(mode.name)
                .font(.caption)
        }
        .frame(width: 80, height: 80)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )
    }
}
