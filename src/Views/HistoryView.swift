import SwiftUI

/// View showing conversion history with Liquid Glass design
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""

    var filteredHistory: [ConversionRecord] {
        if searchText.isEmpty {
            return appState.recentConversions
        }
        return appState.recentConversions.filter { record in
            record.inputFileName.localizedCaseInsensitiveContains(searchText) ||
            record.inputFormat.displayName.localizedCaseInsensitiveContains(searchText) ||
            record.outputFormat.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.recentConversions.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search conversions")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Conversions", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Your conversion history will appear here")
        }
    }

    private var historyList: some View {
        List {
            ForEach(groupedByDate, id: \.0) { date, records in
                Section(header: Text(date)) {
                    ForEach(records) { record in
                        HistoryRow(record: record)
                    }
                    .onDelete { indexSet in
                        deleteRecords(at: indexSet, in: records)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedByDate: [(String, [ConversionRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredHistory) { record in
            if calendar.isDateInToday(record.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(record.timestamp) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: record.timestamp)
            }
        }
        return grouped.sorted { $0.value.first?.timestamp ?? Date() > $1.value.first?.timestamp ?? Date() }
    }

    private func deleteRecords(at indexSet: IndexSet, in records: [ConversionRecord]) {
        let idsToDelete = indexSet.map { records[$0].id }
        appState.recentConversions.removeAll { idsToDelete.contains($0.id) }
    }
}

/// Row for displaying a conversion record
struct HistoryRow: View {
    let record: ConversionRecord

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(record.success ? .green : .red)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.inputFileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(record.inputFormat.displayName)
                        .foregroundStyle(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(record.outputFormat.displayName)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            Spacer()

            Text(record.displayDate)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environment(AppState())
}
