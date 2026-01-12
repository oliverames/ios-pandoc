import SwiftUI
import WebKit

/// Preview component for converted document output
struct OutputPreview: View {
    let content: String
    let format: DocumentFormat
    @State private var showFullScreen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Output Preview", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)

                Spacer()

                Button {
                    showFullScreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Preview content
            Group {
                if format == .html || format == .html5 {
                    WebPreview(htmlContent: content)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ScrollView {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 300)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .sheet(isPresented: $showFullScreen) {
            FullScreenPreview(content: content, format: format)
        }
    }
}

/// Full-screen preview sheet
struct FullScreenPreview: View {
    let content: String
    let format: DocumentFormat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if format == .html || format == .html5 {
                    WebPreview(htmlContent: content)
                } else {
                    ScrollView {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = content
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
}

/// WebView wrapper for HTML preview
struct WebPreview: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    padding: 16px;
                    margin: 0;
                    background: transparent;
                }
                pre {
                    background: rgba(128, 128, 128, 0.1);
                    padding: 12px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                code {
                    font-family: ui-monospace, monospace;
                    font-size: 14px;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
                table {
                    border-collapse: collapse;
                    width: 100%;
                }
                th, td {
                    border: 1px solid rgba(128, 128, 128, 0.3);
                    padding: 8px;
                    text-align: left;
                }
                blockquote {
                    border-left: 4px solid rgba(128, 128, 128, 0.3);
                    margin-left: 0;
                    padding-left: 16px;
                    color: gray;
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}

#Preview {
    OutputPreview(
        content: """
        # Hello World

        This is a **preview** of converted content.

        ```swift
        let greeting = "Hello"
        print(greeting)
        ```
        """,
        format: .markdown
    )
    .padding()
}
