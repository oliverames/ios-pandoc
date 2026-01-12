import Foundation

/// Conversion mode preference
enum ConversionMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case localOnly = "Local Only"
    case serverOnly = "Server Only"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .auto: return "Use local conversion when possible, fall back to server"
        case .localOnly: return "Only use local conversion (limited formats)"
        case .serverOnly: return "Always use server (requires pandoc-server)"
        }
    }
}

/// Service for document conversion - uses local conversion when possible, falls back to server
actor PandocService {
    private let session: URLSession
    private var baseURL: URL
    private let localConverter = LocalConverter()
    var conversionMode: ConversionMode = .auto

    init(baseURL: URL = URL(string: "http://localhost:3030")!) {
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    func updateBaseURL(_ url: URL) {
        self.baseURL = url
    }

    func setConversionMode(_ mode: ConversionMode) {
        self.conversionMode = mode
    }

    /// Convert a document - tries local conversion first if supported
    func convert(
        document: ConversionDocument,
        from inputFormat: DocumentFormat,
        to outputFormat: DocumentFormat,
        options: ConversionOptions
    ) async throws -> ConversionResult {
        let text = document.textContent ?? ""

        // Determine if we should try local conversion
        let canConvertLocally = LocalConverter.canConvertLocally(from: inputFormat, to: outputFormat)

        switch conversionMode {
        case .localOnly:
            if canConvertLocally {
                return try await convertLocally(text: text, from: inputFormat, to: outputFormat, options: options)
            } else {
                throw PandocError.conversionFailed("Local conversion not supported for \(inputFormat.displayName) to \(outputFormat.displayName)")
            }

        case .serverOnly:
            return try await convertWithServer(document: document, from: inputFormat, to: outputFormat, options: options)

        case .auto:
            if canConvertLocally {
                // Try local first
                do {
                    return try await convertLocally(text: text, from: inputFormat, to: outputFormat, options: options)
                } catch {
                    // Fall back to server
                    return try await convertWithServer(document: document, from: inputFormat, to: outputFormat, options: options)
                }
            } else {
                return try await convertWithServer(document: document, from: inputFormat, to: outputFormat, options: options)
            }
        }
    }

    /// Convert using local converter
    private func convertLocally(
        text: String,
        from inputFormat: DocumentFormat,
        to outputFormat: DocumentFormat,
        options: ConversionOptions
    ) async throws -> ConversionResult {
        let output = try await localConverter.convert(
            text: text,
            from: inputFormat,
            to: outputFormat,
            options: options
        )

        // Save output to temporary file
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(outputFormat.fileExtension)

        try output.write(to: outputURL, atomically: true, encoding: .utf8)

        return ConversionResult(
            success: true,
            outputURL: outputURL,
            preview: String(output.prefix(2000)),
            errorMessage: nil
        )
    }

    /// Convert using Pandoc server
    private func convertWithServer(
        document: ConversionDocument,
        from inputFormat: DocumentFormat,
        to outputFormat: DocumentFormat,
        options: ConversionOptions
    ) async throws -> ConversionResult {
        let endpoint = baseURL.appendingPathComponent("")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Build request body according to Pandoc server API
        let requestBody = PandocRequest(
            text: document.textContent ?? "",
            from: inputFormat.rawValue,
            to: outputFormat.rawValue,
            standalone: options.standalone,
            toc: options.tableOfContents,
            numberSections: options.numberSections,
            wrapText: options.wrapText.rawValue,
            highlightStyle: options.highlightStyle,
            template: options.template,
            variables: options.variables.isEmpty ? nil : options.variables,
            metadata: options.metadata.isEmpty ? nil : options.metadata
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw PandocError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let pandocResponse = try decoder.decode(PandocResponse.self, from: data)

                // Save output to temporary file
                let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(outputFormat.fileExtension)

                try pandocResponse.output.write(to: outputURL, atomically: true, encoding: .utf8)

                return ConversionResult(
                    success: true,
                    outputURL: outputURL,
                    preview: String(pandocResponse.output.prefix(2000)),
                    errorMessage: nil
                )
            } else {
                let errorResponse = try? JSONDecoder().decode(PandocErrorResponse.self, from: data)
                throw PandocError.serverError(
                    statusCode: httpResponse.statusCode,
                    message: errorResponse?.message ?? "Unknown error"
                )
            }
        } catch let error as PandocError {
            throw error
        } catch {
            throw PandocError.networkError(error)
        }
    }

    /// Get Pandoc version from server
    func getVersion() async throws -> String {
        let versionURL = baseURL.appendingPathComponent("version")
        let (data, response) = try await session.data(from: versionURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PandocError.invalidResponse
        }

        return String(data: data, encoding: .utf8) ?? "Unknown"
    }

    /// Check if server is reachable
    func checkHealth() async throws -> Bool {
        do {
            _ = try await getVersion()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Request/Response Types

struct PandocRequest: Encodable {
    let text: String
    let from: String
    let to: String
    let standalone: Bool?
    let toc: Bool?
    let numberSections: Bool?
    let wrapText: String?
    let highlightStyle: String?
    let template: String?
    let variables: [String: String]?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case text, from, to, standalone, toc, template, variables, metadata
        case numberSections = "number-sections"
        case wrapText = "wrap"
        case highlightStyle = "highlight-style"
    }
}

struct PandocResponse: Decodable {
    let output: String
}

struct PandocErrorResponse: Decodable {
    let message: String
}

// MARK: - Errors

enum PandocError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    case fileNotFound
    case conversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Pandoc server"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .fileNotFound:
            return "File not found"
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        }
    }
}
