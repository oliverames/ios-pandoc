import Foundation

/// Service for persisting reference templates to the app's Documents directory
actor TemplateStorage {
    /// Directory where template files are stored
    static var templatesDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("Templates", isDirectory: true)
    }

    /// UserDefaults key for template metadata
    private static let metadataKey = "savedTemplates"

    /// Ensure the templates directory exists
    private func ensureDirectoryExists() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: Self.templatesDirectory.path) {
            try fileManager.createDirectory(at: Self.templatesDirectory, withIntermediateDirectories: true)
        }
    }

    /// Save a template from a source URL (e.g., from file picker)
    func saveTemplate(from sourceURL: URL, name: String) async throws -> ReferenceTemplate {
        try ensureDirectoryExists()

        // Access security-scoped resource
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw TemplateStorageError.accessDenied
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        // Determine template type from extension
        let fileExtension = sourceURL.pathExtension.lowercased()
        guard let templateType = ReferenceTemplate.TemplateType(fileExtension: fileExtension) else {
            throw TemplateStorageError.unsupportedFormat(fileExtension)
        }

        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0

        // Create template metadata
        let template = ReferenceTemplate(
            name: name,
            fileName: sourceURL.lastPathComponent,
            fileSize: fileSize,
            templateType: templateType
        )

        // Copy file to templates directory
        let destinationURL = template.fileURL
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        // Save metadata
        var templates = loadAllTemplates()
        templates.append(template)
        saveMetadata(templates)

        return template
    }

    /// Load all saved templates
    func loadAllTemplates() -> [ReferenceTemplate] {
        guard let data = UserDefaults.standard.data(forKey: Self.metadataKey) else {
            return []
        }

        do {
            let templates = try JSONDecoder().decode([ReferenceTemplate].self, from: data)
            // Filter out templates whose files no longer exist
            return templates.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        } catch {
            return []
        }
    }

    /// Delete a template
    func deleteTemplate(_ template: ReferenceTemplate) throws {
        // Remove file
        if FileManager.default.fileExists(atPath: template.fileURL.path) {
            try FileManager.default.removeItem(at: template.fileURL)
        }

        // Update metadata
        var templates = loadAllTemplates()
        templates.removeAll { $0.id == template.id }
        saveMetadata(templates)
    }

    /// Rename a template
    func renameTemplate(_ template: ReferenceTemplate, to newName: String) {
        var templates = loadAllTemplates()
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].name = newName
            saveMetadata(templates)
        }
    }

    /// Get templates that support a specific output format
    func templates(for format: DocumentFormat) -> [ReferenceTemplate] {
        loadAllTemplates().filter { template in
            template.templateType.supportedOutputFormats.contains(format)
        }
    }

    /// Save metadata to UserDefaults
    private func saveMetadata(_ templates: [ReferenceTemplate]) {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: Self.metadataKey)
        } catch {
            // Silently fail - metadata will be lost but files remain
        }
    }
}

/// Errors that can occur during template storage operations
enum TemplateStorageError: LocalizedError {
    case accessDenied
    case unsupportedFormat(String)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the selected file"
        case .unsupportedFormat(let ext):
            return "Unsupported template format: .\(ext). Please select a .docx, .odt, or .pptx file."
        case .saveFailed(let error):
            return "Failed to save template: \(error.localizedDescription)"
        }
    }
}
