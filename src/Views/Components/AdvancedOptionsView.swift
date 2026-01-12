import SwiftUI

/// Advanced conversion options view
struct AdvancedOptionsView: View {
    @Binding var options: ConversionOptions
    @State private var newVariableName = ""
    @State private var newVariableValue = ""
    @State private var newMetadataKey = ""
    @State private var newMetadataValue = ""

    var body: some View {
        List {
            // Document Options
            Section {
                Toggle("Standalone document", isOn: $options.standalone)
                Toggle("Table of contents", isOn: $options.tableOfContents)
                Toggle("Number sections", isOn: $options.numberSections)
            } header: {
                Label("Document", systemImage: "doc.text")
            } footer: {
                Text("Standalone creates a complete document with header and footer.")
            }

            // Text Options
            Section {
                Picker("Text wrapping", selection: $options.wrapText) {
                    ForEach(ConversionOptions.WrapOption.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
            } header: {
                Label("Text", systemImage: "text.alignleft")
            }

            // Syntax Highlighting
            Section {
                Picker("Highlight style", selection: highlightStyleBinding) {
                    Text("None").tag("")
                    Text("Pygments").tag("pygments")
                    Text("Kate").tag("kate")
                    Text("Monochrome").tag("monochrome")
                    Text("Breeze Dark").tag("breezedark")
                    Text("Espresso").tag("espresso")
                    Text("Haddock").tag("haddock")
                    Text("Tango").tag("tango")
                    Text("Zenburn").tag("zenburn")
                }
            } header: {
                Label("Syntax Highlighting", systemImage: "chevron.left.forwardslash.chevron.right")
            }

            // Template
            Section {
                TextField("Template path", text: templateBinding)
                    .autocapitalization(.none)
            } header: {
                Label("Template", systemImage: "doc.badge.gearshape")
            } footer: {
                Text("Path to a custom Pandoc template file.")
            }

            // Variables
            Section {
                ForEach(Array(options.variables.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .fontWeight(.medium)
                        Spacer()
                        Text(options.variables[key] ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteVariable)

                HStack {
                    TextField("Name", text: $newVariableName)
                        .autocapitalization(.none)
                    TextField("Value", text: $newVariableValue)
                        .autocapitalization(.none)
                    Button {
                        addVariable()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newVariableName.isEmpty || newVariableValue.isEmpty)
                }
            } header: {
                Label("Variables", systemImage: "equal.square")
            } footer: {
                Text("Variables are passed to Pandoc templates.")
            }

            // Metadata
            Section {
                ForEach(Array(options.metadata.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .fontWeight(.medium)
                        Spacer()
                        Text(options.metadata[key] ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteMetadata)

                HStack {
                    TextField("Key", text: $newMetadataKey)
                        .autocapitalization(.none)
                    TextField("Value", text: $newMetadataValue)
                        .autocapitalization(.none)
                    Button {
                        addMetadata()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newMetadataKey.isEmpty || newMetadataValue.isEmpty)
                }
            } header: {
                Label("Metadata", systemImage: "tag")
            } footer: {
                Text("Document metadata like title, author, date.")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Bindings

    private var highlightStyleBinding: Binding<String> {
        Binding(
            get: { options.highlightStyle ?? "" },
            set: { options.highlightStyle = $0.isEmpty ? nil : $0 }
        )
    }

    private var templateBinding: Binding<String> {
        Binding(
            get: { options.template ?? "" },
            set: { options.template = $0.isEmpty ? nil : $0 }
        )
    }

    // MARK: - Actions

    private func addVariable() {
        guard !newVariableName.isEmpty, !newVariableValue.isEmpty else { return }
        options.variables[newVariableName] = newVariableValue
        newVariableName = ""
        newVariableValue = ""
    }

    private func deleteVariable(at offsets: IndexSet) {
        let keys = Array(options.variables.keys.sorted())
        for index in offsets {
            options.variables.removeValue(forKey: keys[index])
        }
    }

    private func addMetadata() {
        guard !newMetadataKey.isEmpty, !newMetadataValue.isEmpty else { return }
        options.metadata[newMetadataKey] = newMetadataValue
        newMetadataKey = ""
        newMetadataValue = ""
    }

    private func deleteMetadata(at offsets: IndexSet) {
        let keys = Array(options.metadata.keys.sorted())
        for index in offsets {
            options.metadata.removeValue(forKey: keys[index])
        }
    }
}

#Preview {
    NavigationStack {
        AdvancedOptionsView(options: .constant(ConversionOptions()))
            .navigationTitle("Advanced Options")
    }
}
