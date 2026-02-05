# Pandoc iOS

A modern iOS front-end for [Pandoc](https://github.com/jgm/pandoc), the universal document converter. Built with iOS 26's Liquid Glass design language.

## Features

- **Universal Document Conversion**: Convert between 50+ input formats and 80+ output formats
- **Reference Templates**: Use custom DOCX, ODT, or PPTX templates for styled output
- **Save to Files**: Export converted documents directly to the iOS Files app
- **Liquid Glass UI**: Beautiful, modern interface using Apple's new design language
- **Live Preview**: See your converted documents before saving
- **Format Categories**: Organized format picker with Markdown, Documents, Web, Presentations, Academic, and more
- **Advanced Options**: Full control over Pandoc conversion parameters
- **Conversion History**: Track all your past conversions

## Requirements

- iOS 26.0+
- Xcode 26.0+
- Swift 6.0+
- Pandoc Server (for full format support)

## Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:oliverames/ios-pandoc.git
   ```

2. Open in Xcode:
   ```bash
   cd ios-pandoc
   open Pandoc.xcodeproj
   ```

3. Build and run on your iOS device or simulator

## Setting Up Pandoc Server

The app includes local conversion support for common formats (Markdown ↔ HTML ↔ Plain Text). For full format support, run a Pandoc server:

### Option 1: Using Homebrew (macOS)

```bash
brew install pandoc
pandoc-server --port 3030
```

### Option 2: Using Docker

```bash
docker run -p 3030:3030 pandoc/minimal pandoc-server --port 3030
```

### Option 3: Using Cabal (Haskell)

```bash
cabal install pandoc-cli
pandoc-server --port 3030
```

## App Structure

The app has four main tabs:

| Tab | Description |
|-----|-------------|
| **Convert** | Import documents, select formats, and convert |
| **Templates** | Manage reference documents for DOCX/ODT/PPTX styling |
| **History** | View past conversions |
| **Settings** | Configure server URL and conversion preferences |

## Project Structure

```
ios-pandoc/
├── src/
│   ├── PandocApp.swift              # App entry point & AppState
│   ├── Models/
│   │   ├── DocumentFormat.swift     # Supported formats enum
│   │   ├── ConversionRecord.swift   # Conversion history & options
│   │   ├── ReferenceTemplate.swift  # Template model for DOCX/ODT/PPTX
│   │   └── ConvertedDocument.swift  # FileDocument for export
│   ├── Views/
│   │   ├── ContentView.swift        # Main tab navigation
│   │   ├── ConvertView.swift        # Document conversion UI
│   │   ├── TemplatesView.swift      # Template management UI
│   │   ├── HistoryView.swift        # Conversion history
│   │   ├── SettingsView.swift       # App settings
│   │   └── Components/              # Reusable UI components
│   ├── ViewModels/
│   │   ├── ConvertViewModel.swift   # Conversion logic
│   │   └── TemplatesViewModel.swift # Template management logic
│   ├── Services/
│   │   ├── PandocService.swift      # Pandoc server API
│   │   ├── LocalConverter.swift     # Native iOS conversion
│   │   └── TemplateStorage.swift    # Template persistence
│   └── Assets.xcassets/             # App assets
├── data/                            # Sample files
└── doc/                             # Documentation
```

## Supported Formats

### Input Formats
- **Markdown**: Pandoc, CommonMark, GFM, Strict
- **Documents**: DOCX, ODT, RTF, EPUB
- **Web**: HTML
- **Academic**: LaTeX, reStructuredText, AsciiDoc, Org Mode
- **Wiki**: MediaWiki, DokuWiki
- **Data**: JSON, CSV
- **Other**: Jupyter Notebooks, BibTeX

### Output Formats
All input formats plus:
- **Presentations**: PowerPoint, reveal.js, Slidy, Beamer
- **PDF** (via LaTeX)
- **Plain Text**

## Reference Templates

Pandoc supports custom styling for DOCX, ODT, and PPTX output via reference documents. To use:

1. Go to the **Templates** tab
2. Tap **+** to import a styled .docx, .odt, or .pptx file
3. When converting to that format, select your template from the picker
4. The output will use your template's styles (fonts, colors, margins, etc.)

**Creating a template**: Start with a document that has the styles you want, then import it. Pandoc uses the styles but ignores the content.

## Architecture

The app follows MVVM architecture with:

- **Models**: Pure data types for formats, records, templates, and options
- **Views**: SwiftUI views with Liquid Glass styling
- **ViewModels**: @Observable classes managing state and logic
- **Services**: Actor-based async service layer

## API Reference

### PandocService

```swift
let service = PandocService()

// Convert a document with optional template
let result = try await service.convert(
    document: document,
    from: .markdown,
    to: .docx,
    options: ConversionOptions(),
    referenceTemplate: myTemplate  // Optional
)

// Check server health
let isHealthy = try await service.checkHealth()
```

### ConversionOptions

```swift
var options = ConversionOptions()
options.standalone = true
options.tableOfContents = true
options.numberSections = true
options.highlightStyle = "pygments"
options.variables = ["title": "My Document"]
options.metadata = ["author": "John Doe"]
```

## License

This project is available under the MIT License. See LICENSE for details.

Pandoc itself is licensed under GPLv2+. See https://github.com/jgm/pandoc/blob/main/COPYRIGHT for details.

## Acknowledgments

- [John MacFarlane](https://github.com/jgm) for creating Pandoc
- Apple for the iOS 26 SDK and Liquid Glass design language
