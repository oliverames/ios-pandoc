import SwiftUI

/// Sheet for pasting or typing text content
struct TextInputSheet: View {
    @Bindable var viewModel: ConvertViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var fileName = "untitled.md"
    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // File name input
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)

                    TextField("File name", text: $fileName)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(.ultraThinMaterial)

                Divider()

                // Text editor
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .focused($isTextFocused)
                    .scrollContentBackground(.hidden)
                    .padding()

                // Character count
                HStack {
                    Text("\(text.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Paste from Clipboard") {
                        if let clipboardText = UIPasteboard.general.string {
                            text = clipboardText
                        }
                    }
                    .font(.caption)
                    .disabled(UIPasteboard.general.string == nil)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Enter Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.inputDocument = ConversionDocument(
                            text: text,
                            fileName: fileName
                        )
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                isTextFocused = true
            }
        }
    }
}

#Preview {
    TextInputSheet(viewModel: ConvertViewModel())
}
