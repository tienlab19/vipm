import SwiftUI

struct GoProView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 19, weight: .medium))
                            .foregroundStyle(Color(0xA9BED3)).frame(width: 44, height: 44)
                    }.accessibilityLabel("Close Premium")
                }
                Image(systemName: "star").font(.system(size: 34, weight: .medium)).foregroundStyle(Color(0x1B1300))
                    .frame(width: 72, height: 72)
                    .background(LinearGradient(colors: [Color(0xFBBF57), .amber], startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 20))
                    .shadow(color: Color.amber.opacity(0.25), radius: 17, y: 12)
                Text("Unlock the full\nquestion bank").font(.h(28, .bold)).foregroundStyle(.white).padding(.top, 22)
                Text("More ways to learn. One focused place to prepare for your next step.")
                    .font(.system(size: 14)).foregroundStyle(Color(0xA9BED3)).padding(.top, 10)
                VStack(alignment: .leading, spacing: 18) {
                    benefit("The complete question bank & explanations")
                    benefit("Unlimited timed practice exams")
                    benefit("Missed & incorrect review modes")
                    benefit("A focused, ad-free study experience")
                }.padding(.top, 26)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Coming soon").font(.h(28, .bold)).foregroundStyle(.white)
                    Text("Purchases are not configured in this build. No payment is collected and no purchase can be restored yet.")
                        .font(.system(size: 13)).foregroundStyle(Color(0xA9BED3))
                    Text("Go Premium · unavailable").font(.h(16, .bold)).foregroundStyle(Color(0x1B1300))
                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                        .background(LinearGradient(colors: [Color(0xFBBF57), .amber], startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 15))
                        .accessibilityLabel("Premium purchases unavailable")
                    Button("Restore purchase") {}.disabled(true)
                        .font(.system(size: 12.5)).foregroundStyle(Color(0xA9BED3)).frame(maxWidth: .infinity, minHeight: 44)
                }.padding(.top, 52)
            }.padding(.horizontal, 26).padding(.top, 10).padding(.bottom, 28)
        }
        .background {
            RadialGradient(colors: [Color(0x1C3350), Color(0x101D2E)], center: .top, startRadius: 0, endRadius: 620).ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }

    private func benefit(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: 13) {
            Image(systemName: "checkmark").font(.system(size: 11, weight: .black)).foregroundStyle(Color(0xFBBF57))
                .frame(width: 26, height: 26).background(Color(0xFBBF57).opacity(0.16), in: .rect(cornerRadius: 8))
            Text(text).font(.system(size: 14.5)).foregroundStyle(Color(0xE4ECF5))
        }
    }
}

struct PracticeExamView: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Binding var path: [Route]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.slate2).frame(width: 44, height: 44)
                        .background(.white, in: .rect(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(0xE2E8F0)))
                }
                .accessibilityLabel("Back to home")
                Text("Practice Exam").font(.h(18))
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 16) {
                    hero
                    HStack(spacing: 10) {
                        stat("\(min(viewModel.study.examCount, viewModel.study.examQuestions.count))", "Questions", .navy)
                        stat("\(viewModel.study.examMinutes)", "Minutes", .navy)
                        stat("\(Int(viewModel.study.passBar * 100))%", "To pass", .green)
                    }
                    expectations
                    if viewModel.study.examQuestions.count < viewModel.study.examCount {
                        Label("This bank contains \(viewModel.study.examQuestions.count) available multiple-choice questions. A full mock exam needs \(viewModel.study.examCount).", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(Color.slate).padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
            }

            Button { path.append(.quiz("exam")) } label: {
                Group {
                    if viewModel.study.draft(for: "exam") != nil { Text("Resume exam") }
                    else if viewModel.study.bank.isDemo { Text("Start demo exam") }
                    else { Text("Start exam") }
                }
                    .font(.h(15.5)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.brand, in: .rect(cornerRadius: 15))
                    .shadow(color: Color.brand.opacity(0.28), radius: 12, y: 10)
            }
            .disabled(viewModel.study.examQuestions.isEmpty)
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 16)
        }
        .background(Color.bg)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var askedCount: Int { min(viewModel.study.examCount, viewModel.study.examQuestions.count) }
    private var passMark: Int { Int((Double(askedCount) * viewModel.study.passBar).rounded(.up)) }
    private var passPercent: String { "\(Int(viewModel.study.passBar * 100))%" }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(Color(0x4C6FEF)).frame(width: 6, height: 6)
                Text("Professional Scrum Product Owner I")
                    .font(.system(size: 11.5, weight: .medium)).foregroundStyle(Color(0xC7D8EA))
            }
            .padding(.horizontal, 11).padding(.vertical, 5)
            .background(.white.opacity(0.10), in: .capsule)
            .overlay(Capsule().stroke(.white.opacity(0.14)))

            (viewModel.study.examQuestions.count < viewModel.study.examCount ? Text("Your practice starts here") : Text("Full mock exam"))
                .font(.h(23, .bold)).foregroundStyle(.white).padding(.top, 16)
            Group {
                if viewModel.study.bank.isDemo {
                    Text("Try the complete exam flow with the illustrative questions from your JSON schema.")
                } else {
                    Text("Runs the format of the real Professional Scrum Product Owner I assessment: \(viewModel.study.examCount) questions, \(viewModel.study.examMinutes) minutes, \(passPercent) to pass.")
                }
            }
            .font(.system(size: 13.5)).foregroundStyle(Color(0xA9BED3)).padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(LinearGradient(colors: [.navy, Color(0x223B54)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 22))
    }

    private var expectations: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What to expect").font(.h(14.5))
            row("clock", "\(viewModel.study.examMinutes):00 on the clock, like the real PSPO I — the exam auto-submits at zero.")
            row("square.grid.3x3", "Answer in any order: jump between questions and flag the ones to revisit.")
            row("shuffle", "Every attempt draws a fresh form spread across the topics in your bank.")
            row("eye.slash", "No feedback during the exam; full explanations unlock the moment you submit.")
            row("target", "\(passMark) of \(askedCount) correct is the \(passPercent) pass mark. Unanswered counts as wrong.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(18)
    }

    private func row(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 15, weight: .medium)).foregroundStyle(Color.brand)
            Text(text).font(.system(size: 13)).foregroundStyle(Color.slate2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stat(_ value: String, _ label: LocalizedStringKey, _ tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.h(24, .bold)).foregroundStyle(tint)
            Text(label).font(.system(size: 11.5)).foregroundStyle(Color.slate)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .background(.white, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hairline, lineWidth: 0.75))
        .shadow(color: Color.navy.opacity(0.05), radius: 10, y: 5)
    }
}
