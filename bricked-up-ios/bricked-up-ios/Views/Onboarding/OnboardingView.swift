import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showModeEditor = false

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                Text("Welcome to Bricked Up")
                    .font(.largeTitle.bold())
                Text("Take back control of your screen time using a physical NFC chip.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button("Get Started") { currentPage = 1 }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Spacer().frame(height: 40)
            }
            .tag(0)

            // Page 2: Register NFC
            VStack(spacing: 24) {
                NFCRegistrationView()
                Button("Continue") { currentPage = 2 }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 40)
            }
            .tag(1)

            // Page 3: Create first mode
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Create Your First Mode")
                    .font(.title2.bold())
                Text("Choose which apps and websites to block.")
                    .foregroundStyle(.secondary)

                Button("Create Mode") {
                    showModeEditor = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for Now") {
                    hasCompletedOnboarding = true
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Done") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 40)
            }
            .tag(2)
            .sheet(isPresented: $showModeEditor) {
                NavigationStack {
                    ModeEditorView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showModeEditor = false }
                            }
                        }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}
