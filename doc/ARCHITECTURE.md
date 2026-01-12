# Architecture

## Overview

Pandoc iOS follows the Model-View-ViewModel (MVVM) architectural pattern, with a service layer for handling external communications.

## Layers

### Models

Pure data structures representing:

- **DocumentFormat**: Enum of all supported Pandoc formats with metadata
- **ConversionRecord**: History record of past conversions
- **ConversionOptions**: Configuration options for Pandoc
- **ConversionDocument**: Input document representation

### Views

SwiftUI views styled with Liquid Glass design:

- **ContentView**: Root tab navigation
- **ConvertView**: Main conversion interface
- **HistoryView**: Conversion history list
- **SettingsView**: App configuration
- **Components/**: Reusable UI elements

### ViewModels

Observable classes managing state and business logic:

- **ConvertViewModel**: Handles document loading, format selection, and conversion orchestration
- **AppState**: Global app state shared via environment

### Services

Actor-based async services:

- **PandocService**: Communicates with Pandoc server API

## Data Flow

```
User Action → View → ViewModel → Service → Pandoc Server
                ↓
            State Update
                ↓
             View Re-render
```

## Concurrency

- Services use Swift actors for thread safety
- ViewModels are `@Observable` with `@MainActor` isolation
- All UI updates happen on main thread automatically

## Dependency Injection

- AppState injected via SwiftUI `@Environment`
- Services created as constants in ViewModels

## Error Handling

- PandocError enum for typed errors
- Errors displayed in UI via alert/inline messaging
- Network errors include retry capability

## Persistence

- **@AppStorage**: User preferences
- **Conversion History**: Stored in memory (could extend to Core Data)
- **Documents**: Security-scoped URLs with proper lifecycle management
