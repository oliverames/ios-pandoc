import SwiftUI

/// ViewModel for managing reference document templates
@MainActor
@Observable
final class TemplatesViewModel {
    var templates: [ReferenceTemplate] = []
    var isImporting = false
    var errorMessage: String?
    var showingError = false

    private let storage = TemplateStorage()

    /// Templates grouped by type for sectioned display
    var groupedTemplates: [(type: ReferenceTemplate.TemplateType, templates: [ReferenceTemplate])] {
        ReferenceTemplate.TemplateType.allCases.compactMap { type in
            let templatesOfType = templates.filter { $0.templateType == type }
            guard !templatesOfType.isEmpty else { return nil }
            return (type, templatesOfType)
        }
    }

    /// Load all templates from storage
    func loadTemplates() async {
        templates = await storage.loadAllTemplates()
    }

    /// Add a new template from a file URL
    func addTemplate(from url: URL) async {
        do {
            // Use filename without extension as default name
            let defaultName = url.deletingPathExtension().lastPathComponent
            let template = try await storage.saveTemplate(from: url, name: defaultName)
            templates.append(template)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    /// Delete a template
    func deleteTemplate(_ template: ReferenceTemplate) {
        Task {
            do {
                try await storage.deleteTemplate(template)
                templates.removeAll { $0.id == template.id }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    /// Delete templates at index set (for List onDelete)
    func deleteTemplates(at offsets: IndexSet, in section: ReferenceTemplate.TemplateType) {
        let templatesInSection = templates.filter { $0.templateType == section }
        for index in offsets {
            let template = templatesInSection[index]
            deleteTemplate(template)
        }
    }

    /// Rename a template
    func renameTemplate(_ template: ReferenceTemplate, to newName: String) {
        Task {
            await storage.renameTemplate(template, to: newName)
            if let index = templates.firstIndex(where: { $0.id == template.id }) {
                templates[index].name = newName
            }
        }
    }

    /// Get templates for a specific output format
    func templates(for format: DocumentFormat) -> [ReferenceTemplate] {
        templates.filter { $0.templateType.supportedOutputFormats.contains(format) }
    }
}
