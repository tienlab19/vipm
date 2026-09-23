import SwiftUI

extension Color {
    init(_ hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255,
                  green: Double(hex >> 8 & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
    static let bg = Color(0xEEF2F7)
    static let navy = Color(0x16283B)
    static let navy2 = Color(0x1E3A52)
    static let brand = Color(0x4263EB)
    static let brandSoft = Color(0xEDF1FE)
    static let green = Color(0x12B886)
    static let amber = Color(0xF59E0B)
    static let red = Color(0xEF4444)
    static let hairline = Color(0xE7EDF4)
    static let slate = Color(0x64748B)
    static let slate2 = Color(0x334155)
}

extension Font {
    static func h(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
}

extension View {
    /// Elevated surface with a soft, layered shadow for a modern depth effect.
    func card(_ padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        self.padding(padding)
            .background(.white, in: .rect(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.hairline, lineWidth: 0.75))
            .shadow(color: Color.navy.opacity(0.06), radius: 18, y: 9)
            .shadow(color: Color.navy.opacity(0.03), radius: 3, y: 1)
    }

    func pinnedHeader(background: Color = .bg) -> some View {
        self.frame(maxWidth: .infinity)
            .background(background)
            .overlay(alignment: .bottom) { Divider() }
            .zIndex(1)
    }
}

struct IconChip: View {
    let systemName: String
    var tint: Color = .brand
    var size: CGFloat = 46

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.37, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12), in: .rect(cornerRadius: size * 0.29))
    }
}

extension String {
    var plain: String {
        replacingOccurrences(of: "(?is)<(script|style|iframe|object)[^>]*>.*?</\\1>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?i)<br\\s*/?>|</p>|</div>|</li>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "(?i)<li[^>]*>", with: "• ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&ndash;", with: "–")
            .replacingOccurrences(of: "&mdash;", with: "—")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RichText: View {
    let html: String
    var size: CGFloat = 15
    var weight: Font.Weight = .regular
    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        Text(attributedText).font(.system(size: size * scale, weight: weight))
            .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributedText: AttributedString {
        // ponytail: basic inline HTML only; use a dedicated renderer if imported content requires tables or complex CSS.
        let markdown = html
            .replacingOccurrences(of: "(?i)</?(strong|b)>", with: "**", options: .regularExpression)
            .replacingOccurrences(of: "(?i)</?(em|i)>", with: "*", options: .regularExpression).plain
        return (try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(markdown)
    }
}

struct QuestionImage: View {
    let url: URL?
    var label = "Question illustration"

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty: ProgressView().frame(maxWidth: .infinity, minHeight: 80)
                case .success(let image): image.resizable().scaledToFit().frame(maxHeight: 260)
                case .failure: Label("Image unavailable", systemImage: "photo.badge.exclamationmark").font(.caption)
                @unknown default: EmptyView()
                }
            }.accessibilityLabel(label)
        }
    }
}

struct PrimaryButton: View {
    let title: LocalizedStringKey
    var color: Color = .brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.h(15.5)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(LinearGradient(colors: [color.opacity(0.92), color], startPoint: .top, endPoint: .bottom),
                            in: .rect(cornerRadius: 16))
                .shadow(color: color.opacity(0.32), radius: 14, y: 8)
        }.buttonStyle(.plain)
    }
}

struct AppConfirmationDialog: View {
    let title: LocalizedStringKey
    let message: Text
    let primaryTitle: LocalizedStringKey
    let secondaryTitle: LocalizedStringKey
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        ZStack {
            Color.navy.opacity(0.34).ignoresSafeArea().onTapGesture(perform: secondaryAction)
            VStack(spacing: 18) {
                IconChip(systemName: "exclamationmark.triangle.fill", tint: .amber, size: 52)
                VStack(spacing: 8) {
                    Text(title).font(.h(20)).foregroundStyle(Color.navy).multilineTextAlignment(.center)
                    message.font(.system(size: 15)).foregroundStyle(Color.slate).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: 8) {
                    PrimaryButton(title: primaryTitle, color: .navy, action: primaryAction)
                    Button(action: secondaryAction) {
                        Text(secondaryTitle).font(.h(14)).foregroundStyle(Color.brand)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(.white, in: .rect(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.hairline, lineWidth: 0.75))
            .shadow(color: Color.navy.opacity(0.18), radius: 30, y: 16)
            .padding(.horizontal, 24)
            .accessibilityElement(children: .contain)
        }
    }
}

func mmss(_ seconds: Int) -> String {
    String(format: "%02d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
}

func hhmmss(_ seconds: Int) -> String {
    let seconds = max(0, seconds)
    return seconds < 3_600 ? mmss(seconds) : String(format: "%d:%02d:%02d", seconds / 3_600, seconds % 3_600 / 60, seconds % 60)
}
