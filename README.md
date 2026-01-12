# Pandoc iOS

A modern iOS front-end for [Pandoc](https://github.com/jgm/pandoc), the universal document converter. Built with iOS 26's Liquid Glass design language.

## Features

- **Universal Document Conversion**: Convert between 50+ input formats and 80+ output formats
- **Liquid Glass UI**: Beautiful, modern interface using Apple's new design language
- **Live Preview**: See your converted documents in real-time
- **Format Categories**: Organized format picker with Markdown, Documents, Web, Presentations, Academic, and more
- **Advanced Options**: Full control over Pandoc conversion parameters
- **Conversion History**: Track all your past conversions
- **Share & Export**: Easy sharing and saving of converted documents

## Requirements

- iOS 26.0+
- Xcode 26.0+
- Swift 6.0+
- Pandoc Server (for document conversion)

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

This app requires a Pandoc server to perform document conversions. You can run one locally:

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

## Project Structure

```
ios-pandoc/
├── src/
│   ├── PandocApp.swift           # App entry point
│   ├── Models/
│   │   ├── DocumentFormat.swift   # Supported formats
│   │   └── ConversionRecord.swift # Conversion records
│   ├── Views/
│   │   ├── ContentView.swift      # Main tab view
│   │   ├── ConvertView.swift      # Document conversion
│   │   ├── HistoryView.swift      # Conversion history
│   │   ├── SettingsView.swift     # App settings
│   │   └── Components/            # Reusable UI components
│   ├── ViewModels/
│   │   └── ConvertViewModel.swift # Conversion logic
│   ├── Services/
│   │   └── PandocService.swift    # Pandoc server API
│   └── Assets.xcassets/           # App assets
├── data/                          # Templates & resources
├── doc/                           # Documentation
└── test/                          # Tests
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

## Liquid Glass Design

This app showcases iOS 26's new Liquid Glass design language:

- **Glass Effects**: Translucent materials that refract and reflect light
- **Adaptive Tinting**: UI adapts to content underneath
- **Interactive Feedback**: Touch interactions with shimmer and bounce
- **Fluid Transitions**: Smooth morphing between UI states

### Key SwiftUI APIs Used

```swift
// Apply glass effect to views
View()
    .glassEffect()

// Group glass elements
GlassEffectContainer {
    // Multiple glass views
}

// Tab bar that minimizes on scroll
TabView { }
    .tabBarMinimizeBehavior(.onScrollDown)

// Extra large buttons
Button("Convert") { }
    .controlSize(.extraLarge)
```

## Architecture

The app follows MVVM architecture with:

- **Models**: Pure data types for formats, records, and options
- **Views**: SwiftUI views with Liquid Glass styling
- **ViewModels**: @Observable classes managing state and logic
- **Services**: Actor-based async service layer

## API Reference

### PandocService

```swift
let service = PandocService()

// Convert a document
let result = try await service.convert(
    document: document,
    from: .markdown,
    to: .html,
    options: ConversionOptions()
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

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.

## License

This project is available under the MIT License. See LICENSE for details.

Pandoc itself is licensed under GPLv2+. See https://github.com/jgm/pandoc/blob/main/COPYRIGHT for details.

## Acknowledgments

- [John MacFarlane](https://github.com/jgm) for creating Pandoc
- Apple for the iOS 26 SDK and Liquid Glass design language
