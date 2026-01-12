import Foundation

/// Record of a document conversion operation
struct ConversionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let inputFileName: String
    let inputFormat: DocumentFormat
    let outputFormat: DocumentFormat
    let timestamp: Date
    let success: Bool
    let outputURL: URL?
    let errorMessage: String?

    init(
        id: UUID = UUID(),
        inputFileName: String,
        inputFormat: DocumentFormat,
        outputFormat: DocumentFormat,
        timestamp: Date = Date(),
        success: Bool,
        outputURL: URL? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.inputFileName = inputFileName
        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
        self.timestamp = timestamp
        self.success = success
        self.outputURL = outputURL
        self.errorMessage = errorMessage
    }

    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var conversionDescription: String {
        "\(inputFormat.displayName) → \(outputFormat.displayName)"
    }
}

/// Represents a document to be converted
struct ConversionDocument: Identifiable {
    let id: UUID
    let url: URL
    let fileName: String
    let content: Data?
    let textContent: String?

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.fileName = url.lastPathComponent
        self.content = try? Data(contentsOf: url)
        self.textContent = try? String(contentsOf: url, encoding: .utf8)
    }

    init(text: String, fileName: String = "untitled.md") {
        self.id = UUID()
        self.url = URL(fileURLWithPath: "/tmp/\(fileName)")
        self.fileName = fileName
        self.content = text.data(using: .utf8)
        self.textContent = text
    }
}

/// Options for Pandoc conversion
struct ConversionOptions: Codable, Hashable {
    var standalone: Bool = true
    var tableOfContents: Bool = false
    var numberSections: Bool = false
    var wrapText: WrapOption = .auto
    var highlightStyle: String? = "pygments"
    var template: String?
    var variables: [String: String] = [:]
    var metadata: [String: String] = [:]

    enum WrapOption: String, Codable, CaseIterable {
        case auto
        case none
        case preserve
    }
}
