import SwiftUI

/// Settings view with Liquid Glass design
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("pandocServerURL") private var serverURL = "http://localhost:3030"
    @AppStorage("conversionMode") private var conversionMode = ConversionMode.auto.rawValue
    @AppStorage("defaultInputFormat") private var defaultInputFormat = "markdown"
    @AppStorage("defaultOutputFormat") private var defaultOutputFormat = "html"
    @AppStorage("autoDetectFormat") private var autoDetectFormat = true
    @AppStorage("saveHistory") private var saveHistory = true
    @State private var showingServerTest = false
    @State private var serverTestResult: ServerTestResult?

    var body: some View {
        NavigationStack {
            Form {
                // Conversion Mode
                conversionModeSection

                // Server Configuration
                serverSection

                // Default Formats
                formatSection

                // Behavior
                behaviorSection

                // About
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Conversion Mode Section

    private var conversionModeSection: some View {
        Section {
            Picker("Conversion Engine", selection: $conversionMode) {
                ForEach(ConversionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }

            // Show supported local formats
            if conversionMode != ConversionMode.serverOnly.rawValue {
                NavigationLink {
                    LocalFormatsView()
                } label: {
                    HStack {
                        Text("Supported Local Formats")
                        Spacer()
                        Text("\(LocalConverter.supportedInputFormats.count) in, \(LocalConverter.supportedOutputFormats.count) out")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("Conversion Engine", systemImage: "cpu")
        } footer: {
            Text(ConversionMode(rawValue: conversionMode)?.description ?? "")
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        Section {
            TextField("Server URL", text: $serverURL)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)

            Button {
                testServerConnection()
            } label: {
                HStack {
                    Text("Test Connection")
                    Spacer()
                    if showingServerTest {
                        ProgressView()
                            .controlSize(.small)
                    } else if let result = serverTestResult {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.success ? .green : .red)
                    }
                }
            }
        } header: {
            Label("Pandoc Server", systemImage: "server.rack")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter the URL of your Pandoc server.")
                Text("Run `pandoc-server` to start a local server.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        Section {
            Toggle("Auto-detect input format", isOn: $autoDetectFormat)

            if !autoDetectFormat {
                Picker("Default input format", selection: $defaultInputFormat) {
                    ForEach(DocumentFormat.inputFormats) { format in
                        Text(format.displayName).tag(format.rawValue)
                    }
                }
            }

            Picker("Default output format", selection: $defaultOutputFormat) {
                ForEach(DocumentFormat.outputFormats) { format in
                    Text(format.displayName).tag(format.rawValue)
                }
            }
        } header: {
            Label("Default Formats", systemImage: "doc.text")
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        Section {
            Toggle("Save conversion history", isOn: $saveHistory)

            Button("Clear History", role: .destructive) {
                appState.recentConversions.removeAll()
            }
            .disabled(appState.recentConversions.isEmpty)
        } header: {
            Label("Behavior", systemImage: "gear")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0.0")

            Link(destination: URL(string: "https://github.com/jgm/pandoc")!) {
                HStack {
                    Text("Pandoc on GitHub")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://pandoc.org/MANUAL.html")!) {
                HStack {
                    Text("Pandoc Manual")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("About", systemImage: "info.circle")
        } footer: {
            Text("Pandoc is the universal document converter created by John MacFarlane.")
        }
    }

    // MARK: - Helpers

    private func testServerConnection() {
        showingServerTest = true
        serverTestResult = nil

        Task {
            do {
                guard let url = URL(string: serverURL) else {
                    throw URLError(.badURL)
                }

                let versionURL = url.appendingPathComponent("version")
                let (_, response) = try await URLSession.shared.data(from: versionURL)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    serverTestResult = ServerTestResult(success: true, message: "Connected successfully")
                } else {
                    serverTestResult = ServerTestResult(success: false, message: "Server returned error")
                }
            } catch {
                serverTestResult = ServerTestResult(success: false, message: error.localizedDescription)
            }

            showingServerTest = false
        }
    }
}

struct ServerTestResult {
    let success: Bool
    let message: String
}

#Preview {
    SettingsView()
        .environment(AppState())
}
