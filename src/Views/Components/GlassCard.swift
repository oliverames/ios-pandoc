import SwiftUI

/// Reusable glass card component following Liquid Glass design principles
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 16))
    }
}

/// Glass-styled section header
struct GlassSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .padding(.horizontal, 4)
    }
}

/// Interactive glass button with bounce effect
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var style: Style = .primary

    enum Style {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(tintColor)
        .controlSize(.large)
    }

    private var tintColor: Color {
        switch style {
        case .primary: return .accentColor
        case .secondary: return .secondary
        case .destructive: return .red
        }
    }
}

/// Document preview card with glass styling
struct DocumentPreviewCard: View {
    let fileName: String
    let format: DocumentFormat
    let characterCount: Int?
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Format icon
            Image(systemName: format.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .glassEffect()

            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(format.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    if let count = characterCount {
                        Text("\(count.formatted()) chars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

/// Conversion arrow indicator
struct ConversionArrow: View {
    var body: some View {
        Image(systemName: "arrow.right.circle.fill")
            .font(.title)
            .foregroundStyle(.blue)
            .glassEffect()
    }
}

/// Status badge for conversion results
struct StatusBadge: View {
    let success: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(success ? "Success" : "Failed")
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(success ? .green : .red)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(success ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassCard {
            Text("This is a glass card")
        }

        GlassButton(title: "Convert", icon: "arrow.triangle.2.circlepath") {
            print("Convert tapped")
        }

        DocumentPreviewCard(
            fileName: "document.md",
            format: .markdown,
            characterCount: 1234,
            onRemove: {}
        )

        StatusBadge(success: true)
        StatusBadge(success: false)
    }
    .padding()
}
