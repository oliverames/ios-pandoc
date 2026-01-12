import Foundation

/// Represents all document formats supported by Pandoc
/// Organized into categories for better UI organization
enum DocumentFormat: String, CaseIterable, Identifiable, Codable, Hashable {
    // Markdown variants
    case markdown = "markdown"
    case markdownStrict = "markdown_strict"
    case gfm = "gfm"
    case commonmark = "commonmark"
    case commonmarkX = "commonmark_x"

    // Document formats
    case docx = "docx"
    case odt = "odt"
    case rtf = "rtf"
    case epub = "epub"

    // Web formats
    case html = "html"
    case html5 = "html5"

    // Presentation formats
    case pptx = "pptx"
    case revealjs = "revealjs"
    case slidy = "slidy"
    case beamer = "beamer"

    // Academic/Technical
    case latex = "latex"
    case pdf = "pdf"
    case rst = "rst"
    case asciidoc = "asciidoc"
    case org = "org"
    case mediawiki = "mediawiki"
    case dokuwiki = "dokuwiki"

    // Data formats
    case json = "json"
    case csv = "csv"

    // Plain text
    case plain = "plain"

    // Other
    case ipynb = "ipynb"
    case biblatex = "biblatex"
    case bibtex = "bibtex"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .markdownStrict: return "Markdown (Strict)"
        case .gfm: return "GitHub Flavored Markdown"
        case .commonmark: return "CommonMark"
        case .commonmarkX: return "CommonMark Extended"
        case .docx: return "Microsoft Word"
        case .odt: return "OpenDocument Text"
        case .rtf: return "Rich Text Format"
        case .epub: return "EPUB"
        case .html: return "HTML"
        case .html5: return "HTML5"
        case .pptx: return "PowerPoint"
        case .revealjs: return "reveal.js"
        case .slidy: return "Slidy"
        case .beamer: return "Beamer"
        case .latex: return "LaTeX"
        case .pdf: return "PDF"
        case .rst: return "reStructuredText"
        case .asciidoc: return "AsciiDoc"
        case .org: return "Org Mode"
        case .mediawiki: return "MediaWiki"
        case .dokuwiki: return "DokuWiki"
        case .json: return "JSON"
        case .csv: return "CSV"
        case .plain: return "Plain Text"
        case .ipynb: return "Jupyter Notebook"
        case .biblatex: return "BibLaTeX"
        case .bibtex: return "BibTeX"
        }
    }

    var category: FormatCategory {
        switch self {
        case .markdown, .markdownStrict, .gfm, .commonmark, .commonmarkX:
            return .markdown
        case .docx, .odt, .rtf, .epub:
            return .document
        case .html, .html5:
            return .web
        case .pptx, .revealjs, .slidy, .beamer:
            return .presentation
        case .latex, .pdf, .rst, .asciidoc, .org:
            return .academic
        case .mediawiki, .dokuwiki:
            return .wiki
        case .json, .csv:
            return .data
        case .plain:
            return .text
        case .ipynb, .biblatex, .bibtex:
            return .other
        }
    }

    var fileExtension: String {
        switch self {
        case .markdown, .markdownStrict, .gfm, .commonmark, .commonmarkX: return "md"
        case .docx: return "docx"
        case .odt: return "odt"
        case .rtf: return "rtf"
        case .epub: return "epub"
        case .html, .html5: return "html"
        case .pptx: return "pptx"
        case .revealjs, .slidy: return "html"
        case .beamer: return "pdf"
        case .latex: return "tex"
        case .pdf: return "pdf"
        case .rst: return "rst"
        case .asciidoc: return "adoc"
        case .org: return "org"
        case .mediawiki, .dokuwiki: return "txt"
        case .json: return "json"
        case .csv: return "csv"
        case .plain: return "txt"
        case .ipynb: return "ipynb"
        case .biblatex, .bibtex: return "bib"
        }
    }

    var icon: String {
        switch category {
        case .markdown: return "text.document"
        case .document: return "doc.richtext"
        case .web: return "globe"
        case .presentation: return "play.rectangle"
        case .academic: return "graduationcap"
        case .wiki: return "w.square"
        case .data: return "tablecells"
        case .text: return "text.alignleft"
        case .other: return "doc"
        }
    }

    /// Formats that can be used as input
    static var inputFormats: [DocumentFormat] {
        [
            .markdown, .markdownStrict, .gfm, .commonmark, .commonmarkX,
            .docx, .odt, .rtf, .epub,
            .html, .html5,
            .latex,
            .rst, .asciidoc, .org, .mediawiki, .dokuwiki,
            .json, .csv,
            .ipynb, .biblatex, .bibtex
        ]
    }

    /// Formats that can be used as output
    static var outputFormats: [DocumentFormat] {
        DocumentFormat.allCases
    }
}

/// Categories for organizing document formats
enum FormatCategory: String, CaseIterable, Identifiable {
    case markdown = "Markdown"
    case document = "Documents"
    case web = "Web"
    case presentation = "Presentations"
    case academic = "Academic"
    case wiki = "Wiki"
    case data = "Data"
    case text = "Text"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .markdown: return "text.document"
        case .document: return "doc.richtext"
        case .web: return "globe"
        case .presentation: return "play.rectangle"
        case .academic: return "graduationcap"
        case .wiki: return "w.square"
        case .data: return "tablecells"
        case .text: return "text.alignleft"
        case .other: return "doc"
        }
    }

    var formats: [DocumentFormat] {
        DocumentFormat.allCases.filter { $0.category == self }
    }
}
