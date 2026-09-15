import SwiftUI

private struct TourStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
}

struct ProductTourView: View {
    let onFinish: () -> Void
    @State private var index = 0

    private let steps: [TourStep] = [
        .init(icon: "graduationcap.fill", title: "Welcome to PSPOPrep",
              detail: "Prepare for the Professional Scrum Product Owner I exam with focused practice and full mock tests."),
        .init(icon: "checkmark.seal.fill", title: "Full mock exam",
              detail: "Run the real exam format: 80 questions, 60 minutes, 85% to pass — with a live timer and a question map."),
        .init(icon: "bolt.fill", title: "Flash Challenge",
              detail: "Short on time? Practice a quick random pack of 10, 20 or 30 questions."),
        .init(icon: "timer", title: "Time Trial",
              detail: "Sharpen your speed — answer a timed set under pressure, just like exam day."),
        .init(icon: "scope", title: "Topic Mastery",
              detail: "Pick the parts you want and practice them together to master weak areas."),
        .init(icon: "arrow.triangle.2.circlepath", title: "Review what matters",
              detail: "Revisit your incorrect, missed, and bookmarked questions any time."),
    ]

    private var isLast: Bool { index >= steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { onFinish() }
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(Color(0xC7D8EA))
                    .frame(minHeight: 44).padding(.horizontal, 8)
            }
            .padding(.horizontal, 12).padding(.top, 8)

            TabView(selection: $index) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { i, step in
                    VStack(spacing: 22) {
                        Image(systemName: step.icon).font(.system(size: 52, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 128, height: 128)
                            .background(.white.opacity(0.08), in: .circle)
                            .overlay(Circle().stroke(.white.opacity(0.12)))
                        Text(step.title).font(.h(26, .bold)).foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text(step.detail).font(.system(size: 15)).foregroundStyle(Color(0xC7D8EA))
                            .multilineTextAlignment(.center).lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 34)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: index)

            HStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule().fill(i == index ? Color.white : Color.white.opacity(0.28))
                        .frame(width: i == index ? 22 : 7, height: 7)
                }
            }
            .padding(.bottom, 22)

            HStack(spacing: 12) {
                if index > 0 {
                    Button("Back") { withAnimation { index -= 1 } }
                        .font(.h(15)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.28), lineWidth: 1.5))
                }
                Button(isLast ? "Get started" : "Next") {
                    if isLast { onFinish() } else { withAnimation { index += 1 } }
                }
                .font(.h(15.5)).foregroundStyle(Color.navy)
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(.white, in: .rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24).padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RadialGradient(colors: [Color(0x1C3350), Color(0x101D2E)], center: .top, startRadius: 0, endRadius: 680).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
