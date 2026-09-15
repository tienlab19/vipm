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
                        Button { path.append(.quiz("flash-\(count)")) } label: {
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

struct TopicMasteryView: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Binding var path: [Route]
    @State private var selected: Set<String> = []

    private var selectedCount: Int { viewModel.study.topicQuestions(selected).count }

    var body: some View {
        VStack(spacing: 0) {
            ModeHeader(title: "Topic Mastery") { path.removeLast() }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose the parts to focus on. Questions from every selected part are combined into one session.")
                        .font(.system(size: 13.5)).foregroundStyle(Color.slate2).padding(.bottom, 4)
                    ForEach(viewModel.study.selectableTopics) { part in
                        Button { toggle(part.id) } label: {
                            HStack(spacing: 14) {
                                checkbox(selected.contains(part.id))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(part.name).font(.h(15.5))
                                    Text("\(part.questions.count) questions").font(.caption).foregroundStyle(Color.slate)
                                }
                                Spacer(minLength: 0)
                            }.foregroundStyle(Color.navy).card()
                        }.buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            PrimaryButton(title: selected.isEmpty ? "Select parts to start" : "Start · \(selectedCount) questions") { start() }
                .disabled(selected.isEmpty).opacity(selected.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
        }
        .background(Color.bg)
        .navigationBarBackButtonHidden().toolbar(.hidden, for: .navigationBar)
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func start() {
        guard !selected.isEmpty else { return }
        viewModel.setPendingTopics(selected)
        path.append(.quiz("topics"))
    }

    private func checkbox(_ on: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7).fill(on ? Color.brand : .clear)
            RoundedRectangle(cornerRadius: 7).stroke(on ? Color.brand : Color(0xCBD5E1), lineWidth: 2)
            if on { Image(systemName: "checkmark").font(.system(size: 12, weight: .black)).foregroundStyle(.white) }
        }.frame(width: 26, height: 26)
    }
}
