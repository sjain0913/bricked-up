//
//  ContentView.swift
//  bricked-up-ios
//
//  Created by Saumya Jain on 3/28/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var chips: [NFCChip]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "lock.fill")
                    }

                ModeListView()
                    .tabItem {
                        Label("Modes", systemImage: "square.grid.2x2")
                    }

                ScheduleListView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}
