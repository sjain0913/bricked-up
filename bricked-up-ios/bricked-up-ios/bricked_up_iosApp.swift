//
//  bricked_up_iosApp.swift
//  bricked-up-ios
//
//  Created by Saumya Jain on 3/28/26.
//

import SwiftUI
import SwiftData
import FamilyControls

@main
struct bricked_up_iosApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            NFCChip.self,
            BlockingMode.self,
            BrickSession.self,
            ModeSchedule.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            url: AppConstants.sharedContainerURL.appendingPathComponent("bricked-up.store")
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        do {
                            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        } catch {
                            print("FamilyControls authorization failed: \(error)")
                        }
                    }
                    // Sync all enabled schedules on launch
                    let context = modelContainer.mainContext
                    ScheduleService.shared.syncAllSchedules(modelContext: context)
                }
                .onOpenURL { url in
                    guard url.scheme == "brickedup", url.host == "toggle" else { return }
                    NotificationCenter.default.post(name: .brickedUpToggleFromURL, object: nil)
                }
        }
        .modelContainer(modelContainer)
    }
}
