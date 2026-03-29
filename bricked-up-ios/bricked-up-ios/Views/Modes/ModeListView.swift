import SwiftUI
import SwiftData

struct ModeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlockingMode.sortOrder) private var modes: [BlockingMode]

    var body: some View {
        NavigationStack {
            List {
                ForEach(modes) { mode in
                    NavigationLink {
                        ModeEditorView(mode: mode)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.iconName)
                                .font(.title3)
                                .frame(width: 32)
                            VStack(alignment: .leading) {
                                Text(mode.name)
                                    .font(.headline)
                                let totalWebsites = mode.webDomainCount + mode.customBlockedDomains.count
                                Text("\(mode.appCount) apps, \(totalWebsites) websites")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if mode.isActive {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.red, in: Capsule())
                            }
                        }
                    }
                }
                .onDelete(perform: deleteModes)
            }
            .navigationTitle("Modes")
            .toolbar {
                if modes.count < 10 {
                    NavigationLink {
                        ModeEditorView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if modes.isEmpty {
                    ContentUnavailableView(
                        "No Modes Yet",
                        systemImage: "square.grid.2x2",
                        description: Text("Create a mode to choose which apps to block.")
                    )
                }
            }
        }
    }

    private func deleteModes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(modes[index])
        }
        try? modelContext.save()
    }
}
