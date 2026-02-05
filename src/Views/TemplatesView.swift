import SwiftUI
import UniformTypeIdentifiers

/// View for managing reference document templates
struct TemplatesView: View {
    @State private var viewModel = TemplatesViewModel()
    @State private var showingImporter = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: supportedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .task {
                await viewModel.loadTemplates()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Templates")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add reference documents to customize the styling of your converted DOCX, ODT, and PPTX files.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingImporter = true
            } label: {
                Label("Add Template", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Template List

    private var templateList: some View {
        List {
            ForEach(viewModel.groupedTemplates, id: \.type) { group in
                Section {
                    ForEach(group.templates) { template in
                        TemplateRow(template: template)
                    }
                    .onDelete { offsets in
                        viewModel.deleteTemplates(at: offsets, in: group.type)
                    }
                } header: {
                    Label(group.type.displayName, systemImage: group.type.icon)
                }
            }
        }
    }

    // MARK: - Helpers

    private var supportedContentTypes: [UTType] {
        [
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "odt") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data
        ]
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                Task {
                    await viewModel.addTemplate(from: url)
                }
            }
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
            viewModel.showingError = true
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: ReferenceTemplate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.templateType.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(template.formattedFileSize)
                    Text("•")
                    Text(template.formattedDate)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TemplatesView()
}
