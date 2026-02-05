import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Local document converter using native iOS capabilities
/// Handles common conversions without requiring a server
actor LocalConverter {

    /// Formats that can be converted locally
    static let supportedInputFormats: Set<DocumentFormat> = [
        .markdown, .gfm, .commonmark,
        .html, .html5,
        .plain
    ]

    static let supportedOutputFormats: Set<DocumentFormat> = [
        .html, .html5,
        .plain,
        .markdown
    ]

    /// Check if a conversion can be done locally
    static func canConvertLocally(from: DocumentFormat, to: DocumentFormat) -> Bool {
        supportedInputFormats.contains(from) && supportedOutputFormats.contains(to)
    }

    /// Convert document locally
    func convert(
        text: String,
        from inputFormat: DocumentFormat,
        to outputFormat: DocumentFormat,
        options: ConversionOptions
    ) async throws -> String {
        switch (inputFormat, outputFormat) {
        // Markdown to HTML
        case (.markdown, .html), (.markdown, .html5),
             (.gfm, .html), (.gfm, .html5),
             (.commonmark, .html), (.commonmark, .html5):
            return try await markdownToHTML(text, options: options)

        // HTML to Plain Text
        case (.html, .plain), (.html5, .plain):
            return try htmlToPlainText(text)

        // Markdown to Plain Text
        case (.markdown, .plain), (.gfm, .plain), (.commonmark, .plain):
            let html = try await markdownToHTML(text, options: options)
            return try htmlToPlainText(html)

        // Plain Text to HTML
        case (.plain, .html), (.plain, .html5):
            return plainTextToHTML(text, options: options)

        // HTML to Markdown
        case (.html, .markdown), (.html5, .markdown):
            return try htmlToMarkdown(text)

        // Plain text passthrough
        case (.plain, .plain):
            return text

        // Markdown passthrough (format conversion within markdown family)
        case (.markdown, .markdown), (.gfm, .markdown), (.commonmark, .markdown):
            return text

        default:
            throw LocalConverterError.unsupportedConversion(from: inputFormat, to: outputFormat)
        }
    }

    // MARK: - Markdown to HTML

    private func markdownToHTML(_ markdown: String, options: ConversionOptions) async throws -> String {
        // Use our custom regex-based converter for full HTML output
        return basicMarkdownToHTML(markdown, options: options)
    }

    private func basicMarkdownToHTML(_ markdown: String, options: ConversionOptions) -> String {
        var html = markdown

        // Process in order to avoid conflicts

        // Code blocks (fenced)
        let codeBlockPattern = #"```(\w*)\n([\s\S]*?)```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let range = NSRange(html.startIndex..., in: html)
            html = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "<pre><code class=\"language-$1\">$2</code></pre>")
        }

        // Inline code
        html = html.replacingOccurrences(of: #"`([^`]+)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Headers
        html = html.replacingOccurrences(of: #"^###### (.+)$"#, with: "<h6>$1</h6>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^##### (.+)$"#, with: "<h5>$1</h5>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^#### (.+)$"#, with: "<h4>$1</h4>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^### (.+)$"#, with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^## (.+)$"#, with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^# (.+)$"#, with: "<h1>$1</h1>", options: .regularExpression)

        // Bold and italic
        html = html.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"__(.+?)__"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"_(.+?)_"#, with: "<em>$1</em>", options: .regularExpression)

        // Strikethrough
        html = html.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)

        // Links
        html = html.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)

        // Images
        html = html.replacingOccurrences(of: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)

        // Blockquotes
        html = html.replacingOccurrences(of: #"^> (.+)$"#, with: "<blockquote>$1</blockquote>", options: .regularExpression)

        // Horizontal rules
        html = html.replacingOccurrences(of: #"^---+$"#, with: "<hr>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"^\*\*\*+$"#, with: "<hr>", options: .regularExpression)

        // Unordered lists (simple)
        html = html.replacingOccurrences(of: #"^[\*\-] (.+)$"#, with: "<li>$1</li>", options: .regularExpression)

        // Ordered lists (simple)
        html = html.replacingOccurrences(of: #"^\d+\. (.+)$"#, with: "<li>$1</li>", options: .regularExpression)

        // Paragraphs - wrap non-tagged lines
        let lines = html.components(separatedBy: "\n")
        var processedLines: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                processedLines.append("")
            } else if trimmed.hasPrefix("<") {
                processedLines.append(line)
            } else {
                processedLines.append("<p>\(line)</p>")
            }
        }
        html = processedLines.joined(separator: "\n")

        // Wrap in document if standalone
        if options.standalone {
            html = wrapInHTMLDocument(html, options: options)
        }

        return html
    }

    private func wrapInHTMLDocument(_ body: String, options: ConversionOptions) -> String {
        var toc = ""
        if options.tableOfContents {
            toc = "<nav id=\"toc\"><h2>Table of Contents</h2><!-- TOC would be generated here --></nav>\n"
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Converted Document</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                }
                pre { background: #f5f5f5; padding: 1em; border-radius: 8px; overflow-x: auto; }
                code { font-family: ui-monospace, monospace; }
                blockquote { border-left: 4px solid #ddd; margin: 0; padding-left: 1em; color: #666; }
                img { max-width: 100%; }
            </style>
        </head>
        <body>
        \(toc)\(body)
        </body>
        </html>
        """
    }

    // MARK: - HTML to Plain Text

    private func htmlToPlainText(_ html: String) throws -> String {
        guard let data = html.data(using: .utf8) else {
            throw LocalConverterError.encodingError
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attributedString.string
    }

    // MARK: - Plain Text to HTML

    private func plainTextToHTML(_ text: String, options: ConversionOptions) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let paragraphs = escaped
            .components(separatedBy: "\n\n")
            .map { "<p>\($0.replacingOccurrences(of: "\n", with: "<br>"))</p>" }
            .joined(separator: "\n")

        if options.standalone {
            return wrapInHTMLDocument(paragraphs, options: options)
        }
        return paragraphs
    }

    // MARK: - HTML to Markdown

    private func htmlToMarkdown(_ html: String) throws -> String {
        var markdown = html

        // Remove doctype and html/head/body tags
        markdown = markdown.replacingOccurrences(of: #"<!DOCTYPE[^>]*>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<html[^>]*>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</html>", with: "")
        markdown = markdown.replacingOccurrences(of: #"<head>[\s\S]*?</head>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<body[^>]*>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</body>", with: "")

        // Headers
        markdown = markdown.replacingOccurrences(of: #"<h1[^>]*>([^<]+)</h1>"#, with: "# $1\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h2[^>]*>([^<]+)</h2>"#, with: "## $1\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h3[^>]*>([^<]+)</h3>"#, with: "### $1\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h4[^>]*>([^<]+)</h4>"#, with: "#### $1\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h5[^>]*>([^<]+)</h5>"#, with: "##### $1\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h6[^>]*>([^<]+)</h6>"#, with: "###### $1\n", options: .regularExpression)

        // Bold and italic
        markdown = markdown.replacingOccurrences(of: #"<strong>([^<]+)</strong>"#, with: "**$1**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<b>([^<]+)</b>"#, with: "**$1**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<em>([^<]+)</em>"#, with: "*$1*", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<i>([^<]+)</i>"#, with: "*$1*", options: .regularExpression)

        // Code
        markdown = markdown.replacingOccurrences(of: #"<code>([^<]+)</code>"#, with: "`$1`", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<pre><code[^>]*>([\s\S]*?)</code></pre>"#, with: "```\n$1\n```", options: .regularExpression)

        // Links
        markdown = markdown.replacingOccurrences(of: #"<a href=\"([^\"]+)\">([^<]+)</a>"#, with: "[$2]($1)", options: .regularExpression)

        // Images
        markdown = markdown.replacingOccurrences(of: #"<img[^>]*src=\"([^\"]+)\"[^>]*alt=\"([^\"]*)\"[^>]*>"#, with: "![$2]($1)", options: .regularExpression)

        // Lists
        markdown = markdown.replacingOccurrences(of: #"<li>([^<]+)</li>"#, with: "- $1", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<ul[^>]*>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</ul>", with: "")
        markdown = markdown.replacingOccurrences(of: #"<ol[^>]*>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</ol>", with: "")

        // Paragraphs and breaks
        markdown = markdown.replacingOccurrences(of: #"<p[^>]*>"#, with: "\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</p>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<br>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<br/>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<br />", with: "\n")

        // Blockquotes
        markdown = markdown.replacingOccurrences(of: #"<blockquote[^>]*>"#, with: "> ", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "</blockquote>", with: "")

        // Horizontal rules
        markdown = markdown.replacingOccurrences(of: "<hr>", with: "---\n")
        markdown = markdown.replacingOccurrences(of: "<hr/>", with: "---\n")
        markdown = markdown.replacingOccurrences(of: "<hr />", with: "---\n")

        // Clean up remaining tags and whitespace
        markdown = markdown.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        // Decode HTML entities
        markdown = markdown
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum LocalConverterError: LocalizedError {
    case unsupportedConversion(from: DocumentFormat, to: DocumentFormat)
    case encodingError
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedConversion(let from, let to):
            return "Local conversion from \(from.displayName) to \(to.displayName) is not supported. Using server instead."
        case .encodingError:
            return "Failed to encode document"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
