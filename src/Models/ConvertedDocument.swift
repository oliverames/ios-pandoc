import SwiftUI
import UniformTypeIdentifiers

/// A FileDocument wrapper for exporting converted files via the Files app picker
struct ConvertedDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.data]

    let data: Data
    let contentType: UTType
    let suggestedFilename: String

    /// Initialize from a temporary file URL
    init(url: URL, contentType: UTType, suggestedFilename: String) throws {
        self.data = try Data(contentsOf: url)
        self.contentType = contentType
        self.suggestedFilename = suggestedFilename
    }

    /// Initialize from raw data
    init(data: Data, contentType: UTType, suggestedFilename: String) {
        self.data = data
        self.contentType = contentType
        self.suggestedFilename = suggestedFilename
    }

    /// Required initializer for reading (not used for export-only)
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
        self.contentType = configuration.contentType
        self.suggestedFilename = "document"
    }

    /// Write the document data
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Extension to get UTType from DocumentFormat
extension DocumentFormat {
    var utType: UTType {
        switch self {
        case .markdown, .markdownStrict, .gfm, .commonmark, .commonmarkX:
            return .plainText
        case .docx:
            return UTType(filenameExtension: "docx") ?? .data
        case .odt:
            return UTType(filenameExtension: "odt") ?? .data
        case .rtf:
            return .rtf
        case .epub:
            return UTType(filenameExtension: "epub") ?? .data
        case .html, .html5:
            return .html
        case .pptx:
            return UTType(filenameExtension: "pptx") ?? .data
        case .revealjs, .slidy:
            return .html
        case .beamer:
            return .pdf
        case .latex:
            return UTType(filenameExtension: "tex") ?? .plainText
        case .pdf:
            return .pdf
        case .rst, .asciidoc, .org, .mediawiki, .dokuwiki:
            return .plainText
        case .json:
            return .json
        case .csv:
            return .commaSeparatedText
        case .plain:
            return .plainText
        case .ipynb:
            return .json
        case .biblatex, .bibtex:
            return .plainText
        }
    }
}
