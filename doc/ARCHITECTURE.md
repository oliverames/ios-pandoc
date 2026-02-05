# Architecture

## Overview

Pandoc iOS follows the Model-View-ViewModel (MVVM) architectural pattern, with a service layer for handling external communications and local processing.

## Layers

### Models

Pure data structures representing:

- **DocumentFormat**: Enum of all supported Pandoc formats with metadata (display name, category, file extension, icon)
- **ConversionRecord**: History record of past conversions
- **ConversionOptions**: Configuration options for Pandoc (standalone, TOC, wrap text, etc.)
- **ConversionDocument**: Input document representation with URL and text content
- **ReferenceTemplate**: Template model for DOCX/ODT/PPTX reference documents
- **ConvertedDocument**: FileDocument wrapper for iOS file export

### Views

SwiftUI views styled with Liquid Glass design:

- **ContentView**: Root tab navigation (Convert, Templates, History, Settings)
- **ConvertView**: Main conversion interface with format pickers, template selection, and export
- **TemplatesView**: Template management (import, list, delete)
- **HistoryView**: Conversion history list
- **SettingsView**: App configuration (server URL, conversion mode)
- **Components/**: Reusable UI elements (FormatPicker, GlassCard, etc.)

### ViewModels

Observable classes managing state and business logic:

- **ConvertViewModel**: Handles document loading, format selection, template selection, and conversion orchestration
- **TemplatesViewModel**: Manages template import, storage, and deletion
- **AppState**: Global app state shared via environment (templates, history, server URL)

### Services

Actor-based async services:

- **PandocService**: Communicates with Pandoc server API, routes between local and server conversion
- **LocalConverter**: Native iOS conversion for Markdown ↔ HTML ↔ Plain Text
- **TemplateStorage**: Persists reference templates to Documents folder

## Data Flow

```
User Action → View → ViewModel → Service → Pandoc Server / Local Converter
                ↓
            State Update
                ↓
            View Re-render
```

### Conversion Flow

```
1. User imports document (file or text)
2. User selects input/output formats
3. User optionally selects reference template (for DOCX/ODT/PPTX)
4. User taps Convert
5. ConvertViewModel.convert() is called
6. PandocService determines: local or server conversion?
   - Local: Use LocalConverter for supported format pairs
   - Server: Send request with base64-encoded template if selected
7. Result stored in ConversionResult with preview
8. User previews output
9. User taps "Save to Files" → fileExporter opens
10. On save success, record added to history
```

### Template Flow

```
1. User imports .docx/.odt/.pptx file
2. TemplateStorage copies file to Documents/Templates/
3. Metadata saved to UserDefaults
4. Template appears in TemplatesView and format picker
5. When converting, template's base64 data sent via reference-doc parameter
```

## Concurrency

- **Services**: Use Swift actors for thread safety (`PandocService`, `LocalConverter`, `TemplateStorage`)
- **ViewModels**: `@Observable` with `@MainActor` isolation
- **AppState**: `@MainActor` isolated for UI consistency
- All UI updates happen on main thread automatically

## Dependency Injection

- AppState injected via SwiftUI `@Environment`
- Services created as private constants in ViewModels
- TemplateStorage shared between AppState and TemplatesViewModel

## Error Handling

- **PandocError**: Typed errors for server/network issues
- **LocalConverterError**: Errors for unsupported local conversions
- **TemplateStorageError**: Errors for file access and unsupported formats
- Errors displayed in UI via alerts and inline messaging

## Persistence

| Data | Storage |
|------|---------|
| User preferences | `@AppStorage` (UserDefaults) |
| Conversion history | In-memory array (capped at 50) |
| Reference templates | Files in Documents/Templates/, metadata in UserDefaults |
| Converted documents | Temporary files, user saves via Files app |

## Server API

The app communicates with pandoc-server using JSON:

```json
POST /
{
  "text": "# Hello",
  "from": "markdown",
  "to": "docx",
  "standalone": true,
  "reference-doc": "reference.docx",
  "files": {
    "reference.docx": "<base64-encoded-content>"
  }
}
```

Response:
```json
{
  "output": "<converted-content>"
}
```
