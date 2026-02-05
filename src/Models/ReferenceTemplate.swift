import Foundation

/// Represents a reference document template for DOCX, ODT, or PPTX output
/// These templates define styling that Pandoc applies to generated documents
struct ReferenceTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let fileName: String
    let dateAdded: Date
    let fileSize: Int64
    let templateType: TemplateType

    /// Supported template types matching Pandoc's reference-doc formats
    enum TemplateType: String, Codable, CaseIterable {
        case docx
        case odt
        case pptx

        var displayName: String {
            switch self {
            case .docx: return "Word Document"
            case .odt: return "OpenDocument"
            case .pptx: return "PowerPoint"
            }
        }

        var fileExtension: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .docx: return "doc.fill"
            case .odt: return "doc.text.fill"
            case .pptx: return "play.rectangle.fill"
            }
        }

        /// Output formats that can use this template type
        var supportedOutputFormats: [DocumentFormat] {
            switch self {
            case .docx: return [.docx]
            case .odt: return [.odt]
            case .pptx: return [.pptx]
            }
        }

        /// Initialize from file extension
        init?(fileExtension: String) {
            switch fileExtension.lowercased() {
            case "docx": self = .docx
            case "odt": self = .odt
            case "pptx": self = .pptx
            default: return nil
            }
        }
    }

    /// URL to the template file stored in the app's Documents/Templates directory
    var fileURL: URL {
        TemplateStorage.templatesDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension(templateType.fileExtension)
    }

    /// Formatted file size for display
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// Formatted date for display
    var formattedDate: String {
        dateAdded.formatted(date: .abbreviated, time: .omitted)
    }

    /// Load the template file and encode it as base64 for the Pandoc server API
    func base64EncodedData() throws -> String {
        let data = try Data(contentsOf: fileURL)
        return data.base64EncodedString()
    }

    /// Create a new template from a source file
    init(id: UUID = UUID(), name: String, fileName: String, fileSize: Int64, templateType: TemplateType) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.dateAdded = Date()
        self.fileSize = fileSize
        self.templateType = templateType
    }
}
