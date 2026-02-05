import SwiftUI
import UniformTypeIdentifiers

/// Main conversion view with Liquid Glass design
struct ConvertView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ConvertViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingTextInput = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    inputSection

                    // Format Selection
                    formatSelectionSection

                    // Template Selection (for DOCX/ODT/PPTX)
                    if viewModel.supportsTemplate {
                        templateSelectionSection
                    }

                    // Options Section
                    optionsSection

                    // Convert Button
                    convertButton

                    // Results Section
                    if let result = viewModel.conversionResult {
                        resultSection(result)
                    }
                }
                .padding()
            }
            .navigationTitle("Pandoc")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Import File", systemImage: "doc.badge.plus") {
                            showingDocumentPicker = true
                        }
                        Button("Paste Text", systemImage: "doc.on.clipboard") {
                            showingTextInput = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: supportedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showingTextInput) {
                TextInputSheet(viewModel: viewModel)
            }
            .fileExporter(
                isPresented: $viewModel.showingExporter,
                document: viewModel.convertedDocument,
                contentType: viewModel.outputFormat.utType,
                defaultFilename: viewModel.suggestedFilename
            ) { result in
                handleExportResult(result)
            }
            .task {
                await appState.loadTemplates()
            }
            .onChange(of: viewModel.outputFormat) {
                viewModel.outputFormatChanged()
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Input", systemImage: "doc.text")
                .font(.headline)

            GlassEffectContainer {
                if let document = viewModel.inputDocument {
                    documentCard(document)
                } else {
                    emptyInputCard
                }
            }
        }
    }

    private var emptyInputCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No document selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Import File") {
                    showingDocumentPicker = true
                }
                .buttonStyle(.bordered)

                Button("Paste Text") {
                    showingTextInput = true
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    private func documentCard(_ document: ConversionDocument) -> some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.headline)

                if let content = document.textContent {
                    Text("\(content.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                viewModel.inputDocument = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Format Selection

    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Format", systemImage: "arrow.left.arrow.right")
                .font(.headline)

            GlassEffectContainer {
                VStack(spacing: 12) {
                    // Input Format
                    FormatPicker(
                        title: "From",
                        selection: $viewModel.inputFormat,
                        formats: DocumentFormat.inputFormats
                    )
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 12))

                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    // Output Format
                    FormatPicker(
                        title: "To",
                        selection: $viewModel.outputFormat,
                        formats: DocumentFormat.outputFormats
                    )
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 12))
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Template Selection

    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Template", systemImage: "doc.badge.gearshape")
                .font(.headline)

            GlassEffectContainer {
                VStack(spacing: 0) {
                    let availableTemplates = appState.templates(for: viewModel.outputFormat)

                    if availableTemplates.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("No templates available for \(viewModel.outputFormat.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                    } else {
                        Picker("Reference Template", selection: $viewModel.selectedTemplate) {
                            Text("None (Default)").tag(ReferenceTemplate?.none)
                            ForEach(availableTemplates) { template in
                                HStack {
                                    Image(systemName: template.templateType.icon)
                                    Text(template.name)
                                }
                                .tag(ReferenceTemplate?.some(template))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                    }
                }
                .glassEffect(in: .rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Options", systemImage: "slider.horizontal.3")
                .font(.headline)

            GlassEffectContainer {
                VStack(spacing: 0) {
                    Toggle("Standalone document", isOn: $viewModel.options.standalone)
                        .padding()

                    Divider()

                    Toggle("Table of contents", isOn: $viewModel.options.tableOfContents)
                        .padding()

                    Divider()

                    Toggle("Number sections", isOn: $viewModel.options.numberSections)
                        .padding()

                    Divider()

                    HStack {
                        Text("Text wrapping")
                        Spacer()
                        Picker("", selection: $viewModel.options.wrapText) {
                            ForEach(ConversionOptions.WrapOption.allCases, id: \.self) { option in
                                Text(option.rawValue.capitalized).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                }
                .glassEffect(in: .rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Convert Button

    private var convertButton: some View {
        Button {
            Task {
                await viewModel.convert()
            }
        } label: {
            HStack {
                if viewModel.isConverting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(viewModel.isConverting ? "Converting..." : "Convert")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .disabled(!viewModel.canConvert || viewModel.isConverting)
    }

    // MARK: - Results Section

    private func resultSection(_ result: ConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Result", systemImage: result.success ? "checkmark.circle" : "xmark.circle")
                .font(.headline)
                .foregroundStyle(result.success ? .green : .red)

            GlassEffectContainer {
                VStack(alignment: .leading, spacing: 16) {
                    if result.success {
                        if let preview = result.preview {
                            ScrollView {
                                Text(preview)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
                        }

                        HStack(spacing: 12) {
                            Button {
                                viewModel.showingExporter = true
                            } label: {
                                Label("Save to Files", systemImage: "folder")
                            }
                            .buttonStyle(.borderedProminent)

                            ShareLink(item: result.outputURL ?? URL(fileURLWithPath: "/")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                viewModel.copyToClipboard()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if let error = result.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(in: .rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Helpers

    private var supportedContentTypes: [UTType] {
        [.plainText, .html, .json, .commaSeparatedText, .rtf, .xml, .data]
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                viewModel.loadDocument(from: url)
            }
        case .failure(let error):
            viewModel.showError(error.localizedDescription)
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Add to conversion history
            if let document = viewModel.inputDocument {
                let record = ConversionRecord(
                    inputFileName: document.fileName,
                    inputFormat: viewModel.inputFormat,
                    outputFormat: viewModel.outputFormat,
                    success: true,
                    outputURL: url
                )
                appState.addConversion(record)
            }
        case .failure(let error):
            viewModel.showError(error.localizedDescription)
        }
    }
}

// MARK: - Conversion Result

struct ConversionResult {
    let success: Bool
    let outputURL: URL?
    let preview: String?
    let errorMessage: String?
}

#Preview {
    ConvertView()
        .environment(AppState())
}
