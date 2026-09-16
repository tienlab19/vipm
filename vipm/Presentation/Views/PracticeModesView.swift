import SwiftUI

private struct ModeHeader: View {
    let title: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.slate2).frame(width: 44, height: 44)
                    .background(.white, in: .rect(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(0xE2E8F0)))
            }.accessibilityLabel("Back")
            Text(title).font(.h(18))
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 14)
        .pinnedHeader()
    }
}

struct FlashChallengeView: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Binding var path: [Route]

    private var available: Int { viewModel.study.examQuestions.count }

    var body: some View {
        VStack(spacing: 0) {
            ModeHeader(title: "Flash Challenge") { path.removeLast() }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero
                    ForEach(viewModel.study.flashCounts, id: \.self) { count in
                        Button {
                            Track.log("flash_pack_select", ["count": count])
                            path.append(.quiz("flash-\(count)"))
                        } label: {
                            HStack(spacing: 14) {
                                IconChip(systemName: "bolt.fill", tint: .amber)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(count) questions").font(.h(16))
                                    Text("Random pack · untimed").font(.caption).foregroundStyle(Color.slate)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.slate)
                            }.foregroundStyle(Color.navy).card()
                        }
                        .buttonStyle(.plain)
                        .disabled(available == 0)
                        .opacity(available == 0 ? 0.5 : 1)
                    }
                    if available < (viewModel.study.flashCounts.last ?? 0) {
                        Label("Your bank has \(available) available questions. Smaller packs use what's available.", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(Color.slate).padding(.horizontal, 4)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.bg)
        .navigationBarBackButtonHidden().toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick practice, your way").font(.h(22, .bold)).foregroundStyle(.white)
            Text("Jump right in with a random pack of questions — perfect for studying on the go.")
                .font(.system(size: 13.5)).foregroundStyle(Color(0xA9BED3))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        .background(LinearGradient(colors: [.navy, Color(0x223B54)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 22))
    }
}
