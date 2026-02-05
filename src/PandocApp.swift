import SwiftUI

/// Pandoc iOS - A modern iOS front-end for the universal document converter
/// Built with iOS 26's Liquid Glass design language
@main
struct PandocApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

/// Global app state using the new Observable macro
@MainActor
@Observable
final class AppState {
    var selectedInputFormat: DocumentFormat?
    var selectedOutputFormat: DocumentFormat?
    var isConverting: Bool = false
    var recentConversions: [ConversionRecord] = []
    var pandocServerURL: URL = URL(string: "http://localhost:3030")!

    /// Reference templates for DOCX/ODT/PPTX output
    var templates: [ReferenceTemplate] = []

    private let templateStorage = TemplateStorage()

    func addConversion(_ record: ConversionRecord) {
        recentConversions.insert(record, at: 0)
        if recentConversions.count > 50 {
            recentConversions.removeLast()
        }
    }

    /// Load templates from storage
    func loadTemplates() async {
        templates = await templateStorage.loadAllTemplates()
    }

    /// Get templates that support a specific output format
    func templates(for format: DocumentFormat) -> [ReferenceTemplate] {
        templates.filter { $0.templateType.supportedOutputFormats.contains(format) }
    }

    /// Find a template by ID
    func template(withID id: UUID) -> ReferenceTemplate? {
        templates.first { $0.id == id }
    }
}
