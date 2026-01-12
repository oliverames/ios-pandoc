import SwiftUI

/// View showing formats supported by local converter
struct LocalFormatsView: View {
    var body: some View {
        List {
            Section {
                ForEach(Array(LocalConverter.supportedInputFormats).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { format in
                    FormatInfoRow(format: format)
                }
            } header: {
                Label("Input Formats", systemImage: "arrow.down.doc")
            } footer: {
                Text("These formats can be read and converted locally without a server.")
            }

            Section {
                ForEach(Array(LocalConverter.supportedOutputFormats).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { format in
                    FormatInfoRow(format: format)
                }
            } header: {
                Label("Output Formats", systemImage: "arrow.up.doc")
            } footer: {
                Text("These formats can be generated locally.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Local Conversion")
                        .font(.headline)

                    Text("The local converter uses native iOS capabilities to convert between common formats without needing a Pandoc server.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Supported conversions include:")
                        .font(.subheadline)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        conversionRow("Markdown", "HTML")
                        conversionRow("HTML", "Plain Text")
                        conversionRow("HTML", "Markdown")
                        conversionRow("Plain Text", "HTML")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Label("About", systemImage: "info.circle")
            }
        }
        .navigationTitle("Local Formats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func conversionRow(_ from: String, _ to: String) -> some View {
        HStack {
            Text(from)
            Image(systemName: "arrow.right")
                .font(.caption2)
            Text(to)
        }
    }
}

/// Row showing format info
struct FormatInfoRow: View {
    let format: DocumentFormat

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: format.icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(format.displayName)
                    .font(.body)

                Text(".\(format.fileExtension)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocalFormatsView()
    }
}
