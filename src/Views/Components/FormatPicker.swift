import SwiftUI

/// Format picker component with categorized formats
struct FormatPicker: View {
    let title: String
    @Binding var selection: DocumentFormat
    let formats: [DocumentFormat]

    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: selection.icon)
                        .foregroundStyle(.blue)

                    Text(selection.displayName)
                        .fontWeight(.medium)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            FormatPickerSheet(
                title: title,
                selection: $selection,
                formats: formats
            )
        }
    }
}

/// Full-screen format picker sheet
struct FormatPickerSheet: View {
    let title: String
    @Binding var selection: DocumentFormat
    let formats: [DocumentFormat]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredFormats: [DocumentFormat] {
        if searchText.isEmpty {
            return formats
        }
        return formats.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedFormats: [(FormatCategory, [DocumentFormat])] {
        let grouped = Dictionary(grouping: filteredFormats) { $0.category }
        return FormatCategory.allCases.compactMap { category in
            guard let formats = grouped[category], !formats.isEmpty else { return nil }
            return (category, formats)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedFormats, id: \.0) { category, formats in
                    Section {
                        ForEach(formats) { format in
                            FormatRow(
                                format: format,
                                isSelected: format == selection
                            ) {
                                selection = format
                                dismiss()
                            }
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select \(title) Format")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search formats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Row for a single format option
struct FormatRow: View {
    let format: DocumentFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: format.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(format.displayName)
                        .foregroundStyle(.primary)

                    Text(".\(format.fileExtension)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FormatPicker(
        title: "From",
        selection: .constant(.markdown),
        formats: DocumentFormat.inputFormats
    )
    .padding()
    .glassEffect(in: .rect(cornerRadius: 12))
}
