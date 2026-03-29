import Foundation
import SwiftData

@Observable
final class BrickingService {
    private let nfcService = NFCService()
    private let shieldingService = ShieldingService.shared
    private let appState = AppState.shared

    var isScanning: Bool { nfcService.isScanning }
    var errorMessage: String?

    /// Scans NFC and toggles brick state for the given mode.
    func scanAndToggle(mode: BlockingMode?, modelContext: ModelContext) async {
        do {
            let tagId = try await nfcService.scan()

            // Verify the chip is registered
            let descriptor = FetchDescriptor<NFCChip>(
                predicate: #Predicate { $0.tagIdentifier == tagId }
            )
            guard let _ = try modelContext.fetch(descriptor).first else {
                errorMessage = "Unregistered chip. Please register this chip first."
                return
            }

            if appState.currentState == .unlocked {
                try brick(mode: mode, modelContext: modelContext)
            } else {
                try unbrick(modelContext: modelContext)
            }
            errorMessage = nil
        } catch NFCError.cancelled {
            // User cancelled, do nothing
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Programs a chip with the background NDEF toggle URL.
    func programChip() async throws {
        try await nfcService.writeToggleURL()
    }

    /// Toggles brick state without scanning NFC — used when app is opened via the NDEF URL scheme.
    func toggleDirect(modelContext: ModelContext) async {
        do {
            if appState.currentState == .unlocked {
                // Prefer last used mode, fall back to first available
                let mode = try resolveLastUsedMode(modelContext: modelContext)
                guard let mode else {
                    errorMessage = "No mode set up. Open the app to configure a mode first."
                    return
                }
                try brick(mode: mode, modelContext: modelContext)
            } else {
                try unbrick(modelContext: modelContext)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveLastUsedMode(modelContext: ModelContext) throws -> BlockingMode? {
        if let modeId = appState.lastUsedModeId {
            let descriptor = FetchDescriptor<BlockingMode>(predicate: #Predicate { $0.id == modeId })
            if let mode = try modelContext.fetch(descriptor).first { return mode }
        }
        // Fall back to first mode by sort order
        var descriptor = FetchDescriptor<BlockingMode>(sortBy: [SortDescriptor(\.sortOrder)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Registers a new NFC chip.
    func registerChip(name: String, modelContext: ModelContext) async throws -> NFCChip {
        let tagId = try await nfcService.scan()

        // Check if already registered
        let descriptor = FetchDescriptor<NFCChip>(
            predicate: #Predicate { $0.tagIdentifier == tagId }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let chip = NFCChip(tagIdentifier: tagId, name: name)
        modelContext.insert(chip)
        try modelContext.save()
        return chip
    }

    private func brick(mode: BlockingMode?, modelContext: ModelContext) throws {
        guard let mode else {
            errorMessage = "Please select a blocking mode first."
            return
        }

        // Apply shields
        shieldingService.applyShield(for: mode)

        // Update shared state for extensions
        appState.currentState = .locked
        appState.activeModeId = mode.id
        appState.lastUsedModeId = mode.id
        appState.activeModeData = mode.selectedAppsData
        appState.sessionStartTime = Date()
        AppConstants.sharedDefaults.set(mode.name, forKey: "activeModeName")
        mode.syncToSharedDefaults()

        // Create session record
        let session = BrickSession(modeId: mode.id, modeName: mode.name)
        modelContext.insert(session)

        mode.isActive = true
        try modelContext.save()
    }

    private func unbrick(modelContext: ModelContext) throws {
        // Find and end active session
        let descriptor = FetchDescriptor<BrickSession>(
            predicate: #Predicate { $0.endTime == nil }
        )
        if let activeSession = try modelContext.fetch(descriptor).first {
            activeSession.endTime = Date()
        }

        // Deactivate current mode
        if let modeId = appState.activeModeId {
            let modeDescriptor = FetchDescriptor<BlockingMode>(
                predicate: #Predicate { $0.id == modeId }
            )
            if let mode = try modelContext.fetch(modeDescriptor).first {
                shieldingService.removeShield(for: mode)
                mode.isActive = false
            }
        }

        // Update state
        appState.currentState = .unlocked
        appState.activeModeId = nil
        appState.activeModeData = nil
        appState.sessionStartTime = nil
        AppConstants.sharedDefaults.removeObject(forKey: "activeModeName")

        try modelContext.save()
    }
}
