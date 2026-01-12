import SwiftUI
import UniformTypeIdentifiers

/// ViewModel for the conversion view
@Observable
final class ConvertViewModel {
    var inputDocument: ConversionDocument?
    var inputFormat: DocumentFormat = .markdown
    var outputFormat: DocumentFormat = .html
    var options = ConversionOptions()
    var isConverting = false
    var conversionResult: ConversionResult?
    var errorMessage: String?

    private let pandocService = PandocService()

    var canConvert: Bool {
        inputDocument != nil && inputFormat != outputFormat
    }

    func loadDocument(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showError("Cannot access the selected file")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        inputDocument = ConversionDocument(url: url)

        // Auto-detect format from file extension
        let ext = url.pathExtension.lowercased()
        if let detected = detectFormat(from: ext) {
            inputFormat = detected
        }
    }

    func loadText(_ text: String) {
        inputDocument = ConversionDocument(text: text)
    }

    func convert() async {
        guard let document = inputDocument else { return }

        isConverting = true
        conversionResult = nil
        errorMessage = nil

        do {
            let result = try await pandocService.convert(
                document: document,
                from: inputFormat,
                to: outputFormat,
                options: options
            )

            await MainActor.run {
                conversionResult = result
                isConverting = false
            }
        } catch {
            await MainActor.run {
                conversionResult = ConversionResult(
                    success: false,
                    outputURL: nil,
                    preview: nil,
                    errorMessage: error.localizedDescription
                )
                isConverting = false
            }
        }
    }

    func copyToClipboard() {
        guard let preview = conversionResult?.preview else { return }
        UIPasteboard.general.string = preview
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    private func detectFormat(from extension: String) -> DocumentFormat? {
        switch `extension` {
        case "md", "markdown": return .markdown
        case "html", "htm": return .html
        case "tex", "latex": return .latex
        case "rst": return .rst
        case "adoc", "asciidoc": return .asciidoc
        case "org": return .org
        case "json": return .json
        case "csv": return .csv
        case "rtf": return .rtf
        case "docx": return .docx
        case "odt": return .odt
        case "epub": return .epub
        case "ipynb": return .ipynb
        case "bib": return .bibtex
        default: return nil
        }
    }
}
