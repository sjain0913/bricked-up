import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    let stats = StatsService(modelContext: modelContext)

                    // Streak card
                    HStack(spacing: 24) {
                        StatCard(
                            title: "Current Streak",
                            value: "\(stats.currentStreak())",
                            unit: "days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        StatCard(
                            title: "Longest Streak",
                            value: "\(stats.longestStreak())",
                            unit: "days",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal)

                    // Today's time
                    HStack(spacing: 24) {
                        StatCard(
                            title: "Today",
                            value: formatHours(stats.totalBrickedTime(for: Date()) / 3600),
                            unit: "hours",
                            icon: "clock.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Lifetime",
                            value: formatHours(stats.totalLifetimeHours()),
                            unit: "hours",
                            icon: "hourglass",
                            color: .green
                        )
                    }
                    .padding(.horizontal)

                    // Weekly chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Week")
                            .font(.headline)
                            .padding(.horizontal)

                        let weeklyData = stats.weeklyData()
                        Chart(weeklyData, id: \.date) { item in
                            BarMark(
                                x: .value("Day", item.date, unit: .day),
                                y: .value("Hours", item.hours)
                            )
                            .foregroundStyle(.blue.gradient)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let hours = value.as(Double.self) {
                                        Text("\(hours, specifier: "%.1f")h")
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Recent sessions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .padding(.horizontal)

                        let sessions = stats.recentSessions(limit: 20)
                        if sessions.isEmpty {
                            Text("No sessions yet. Brick your phone to get started!")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(sessions) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.vertical)
            }
            .navigationTitle("Stats")
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 0.1 {
            return String(format: "%.0f", hours * 60)
        }
        return String(format: "%.1f", hours)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionRow: View {
    let session: BrickSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.modeName)
                    .font(.subheadline.bold())
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                Text(session.startTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if session.isActive {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
