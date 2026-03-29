import Foundation
import SwiftData

final class StatsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Precomputed stats snapshot — avoids repeated fetches during a single render.
    struct Snapshot {
        let currentStreak: Int
        let longestStreak: Int
        let todayBrickedSeconds: TimeInterval
        let lifetimeHours: Double
        let weeklyData: [(date: Date, hours: Double)]
        let recentSessions: [BrickSession]
    }

    /// Fetch all data once and compute everything in memory.
    func computeSnapshot(recentLimit: Int = 20) -> Snapshot {
        let allSessions = fetchAllSessions()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Build per-day totals in a single pass
        var dailyTotals: [Date: TimeInterval] = [:]
        var lifetimeTotal: TimeInterval = 0

        for session in allSessions {
            let day = calendar.startOfDay(for: session.startTime)
            let dur = session.duration
            dailyTotals[day, default: 0] += dur
            lifetimeTotal += dur
        }

        // Streaks
        let (current, longest) = computeStreaks(dailyTotals: dailyTotals, today: today, calendar: calendar)

        // Weekly data (last 7 days)
        var weekly: [(date: Date, hours: Double)] = []
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let seconds = dailyTotals[date] ?? 0
            weekly.append((date: date, hours: seconds / 3600))
        }

        // Recent sessions (already sorted descending from fetch)
        let recent = Array(allSessions.prefix(recentLimit))

        return Snapshot(
            currentStreak: current,
            longestStreak: longest,
            todayBrickedSeconds: dailyTotals[today] ?? 0,
            lifetimeHours: lifetimeTotal / 3600,
            weeklyData: weekly,
            recentSessions: recent
        )
    }

    private func fetchAllSessions() -> [BrickSession] {
        let descriptor = FetchDescriptor<BrickSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func computeStreaks(
        dailyTotals: [Date: TimeInterval],
        today: Date,
        calendar: Calendar
    ) -> (current: Int, longest: Int) {
        guard !dailyTotals.isEmpty else { return (0, 0) }

        // Current streak: count consecutive days backwards from today with >= 60s
        var current = 0
        var day = today
        while (dailyTotals[day] ?? 0) >= 60 {
            current += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }

        // Longest streak: iterate from earliest day to today
        guard let earliest = dailyTotals.keys.min() else { return (current, current) }
        var longest = 0
        var streak = 0
        day = earliest

        while day <= today {
            if (dailyTotals[day] ?? 0) >= 60 {
                streak += 1
                longest = max(longest, streak)
            } else {
                streak = 0
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }

        return (current, longest)
    }
}
