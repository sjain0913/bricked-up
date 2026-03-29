import Foundation
import SwiftData

final class StatsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func totalBrickedTime(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<BrickSession>(
            predicate: #Predicate {
                $0.startTime >= startOfDay && $0.startTime < endOfDay
            }
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration }
    }

    func currentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        // Check today first
        if totalBrickedTime(for: date) >= 60 { // At least 1 minute
            streak = 1
        } else {
            return 0
        }

        // Check previous days
        while true {
            date = calendar.date(byAdding: .day, value: -1, to: date)!
            if totalBrickedTime(for: date) >= 60 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    func longestStreak() -> Int {
        let descriptor = FetchDescriptor<BrickSession>(
            sortBy: [SortDescriptor(\.startTime)]
        )
        guard let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        guard let firstDate = sessions.first?.startTime else { return 0 }
        let startDay = calendar.startOfDay(for: firstDate)
        let today = calendar.startOfDay(for: Date())

        var longest = 0
        var current = 0
        var day = startDay

        while day <= today {
            if totalBrickedTime(for: day) >= 60 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }

        return longest
    }

    func weeklyData() -> [(date: Date, hours: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [(date: Date, hours: Double)] = []

        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let time = totalBrickedTime(for: date)
            data.append((date: date, hours: time / 3600))
        }

        return data
    }

    func totalLifetimeHours() -> Double {
        let descriptor = FetchDescriptor<BrickSession>()
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration } / 3600
    }

    func recentSessions(limit: Int = 50) -> [BrickSession] {
        var descriptor = FetchDescriptor<BrickSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
