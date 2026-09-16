import SwiftUI

struct ResultView: View {
    @Environment(StudyViewModel.self) private var viewModel
    let session: QuizSession
    @Binding var path: [Route]
    let retake: () -> Void
    @State private var review = false

    private var passed: Bool { !session.gradedQuestions.isEmpty && session.score >= viewModel.study.passBar }

    var body: some View {
        VStack(spacing: 0) {
            hero
            ScrollView { breakdownSheet }
        }
        .background(Color.bg)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $review) { ReviewList(session: session) }
        .onChange(of: review) { _, shown in if shown { Track.log("result_review_open") } }
        .onAppear {
            Track.log("result_view", ["passed": passed, "is_exam": session.deadline != nil,
                                      "score": Int((session.score * 100).rounded()),
                                      "correct": session.correctCount, "graded": session.gradedQuestions.count])
        }
    }

    private var actionBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Button { review = true } label: {
                    Text("Review answers").font(.h(14)).foregroundStyle(Color.navy)
                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                        .background(.white, in: .rect(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(0xD3DEEA), lineWidth: 1.5))
                }
                PrimaryButton(title: "Retake") { Track.log("result_retake_tap"); retake() }
            }
            Button("Back to home") { Track.log("result_back_home"); path.removeAll() }.font(.subheadline).frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 8)
        .background(.white).overlay(alignment: .top) { Divider() }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: passed ? "checkmark" : "arrow.counterclockwise").font(.system(size: 12, weight: .bold))
                Group {
                    if session.gradedQuestions.isEmpty { Text("Self-review complete") }
                    else if passed { Text("Practice passed") }
                    else { Text("Keep practicing") }
                }
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(passed ? Color(0x7DE9C3) : Color(0xFFD590))
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background((passed ? Color.green : .amber).opacity(0.16), in: .capsule)
            .overlay(Capsule().stroke((passed ? Color.green : .amber).opacity(0.35)))
            ProgressRing(value: session.score, size: 176, lineWidth: 14, track: Color(0x274863), tint: passed ? Color(0x2FD79B) : .amber) {
                VStack(spacing: 4) {
                    Text(verbatim: session.gradedQuestions.isEmpty ? "—" : "\(Int((session.score * 100).rounded()))%")
                        .font(.h(45, .bold)).foregroundStyle(.white)
                    Text("\(session.correctCount) of \(session.gradedQuestions.count) correct").font(.system(size: 12)).foregroundStyle(Color(0xA9BED3))
                }
            }.padding(.top, 22)
            Group {
                if session.gradedQuestions.isEmpty { Text("Reflect on your answers") }
                else if passed { Text("Above the 85% practice bar") }
                else { Text("One step closer") }
            }
                .font(.h(20)).foregroundStyle(.white).padding(.top, 22)
            Group {
                if viewModel.study.bank.isDemo { Text("A result for this demo set, not a prediction of exam readiness.") }
                else if passed { Text("Strong practice result. Review the details to keep improving.") }
                else { Text("Review the missed answers, then try again.") }
            }
                .font(.system(size: 13.5)).foregroundStyle(Color(0xA9BED3)).multilineTextAlignment(.center).padding(.top, 6)
        }.padding(.horizontal, 26).padding(.top, 18).padding(.bottom, 28).frame(maxWidth: .infinity)
            .background(Color.navy.ignoresSafeArea(edges: .top))
    }

    private var breakdownSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                stat("\(session.correctCount)", "Correct", .green)
                stat("\(session.wrongCount)", "Wrong", .red)
                stat(mmss(session.elapsed), "Time", .navy)
            }
            Group {
                if session.deadline == nil {
                    Text("\(session.missedCount) unanswered · \(session.questions.count - session.gradedQuestions.count) self-review (not scored)")
                } else {
                    Text("\(session.correctCount) correct of \(session.gradedQuestions.count) · pass mark \(passMark) · \(session.missedCount) unanswered scored as wrong")
                }
            }
                .font(.caption).foregroundStyle(Color.slate).padding(.top, 12)
            Text("By topic").font(.h(14.5)).padding(.top, 22).padding(.bottom, 12)
            VStack(spacing: 16) {
                ForEach(breakdown, id: \.name) { topic in
                    VStack(spacing: 8) {
                        HStack {
                            Text(topic.name).font(.system(size: 13)).foregroundStyle(Color.slate2)
                            Spacer()
                            Text(verbatim: "\(Int((topic.value * 100).rounded()))%").font(.h(12.5)).foregroundStyle(topic.value >= viewModel.study.passBar ? Color.green : .brand)
                        }
                        ProgressView(value: topic.value).tint(topic.value >= viewModel.study.passBar ? Color.green : .brand).scaleEffect(y: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 24).frame(maxWidth: .infinity)
        .background(Color.bg, in: .rect(topLeadingRadius: 28, topTrailingRadius: 28))
        .background(Color.navy)
    }

    private var passMark: Int { Int((Double(session.gradedQuestions.count) * viewModel.study.passBar).rounded(.up)) }

    private var breakdown: [(name: String, value: Double)] {
        viewModel.study.breakdown(for: session)
    }

    private func stat(_ value: String, _ label: LocalizedStringKey, _ tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(verbatim: value).font(.h(22, .bold)).foregroundStyle(tint).monospacedDigit()
            Text(label).font(.system(size: 11)).foregroundStyle(Color.slate)
        }.frame(maxWidth: .infinity).padding(.vertical, 16).background(.white, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hairline, lineWidth: 0.75))
            .shadow(color: Color.navy.opacity(0.05), radius: 10, y: 5)
    }
}

struct ReviewList: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    let session: QuizSession

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(session.questions) { question in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label(status(question), systemImage: question.isEssay ? "pencil.circle" : session.isCorrect(question) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.caption.weight(.semibold)).foregroundStyle(session.isCorrect(question) ? Color.green : Color.slate)
                                Spacer()
                                Button { viewModel.toggleBookmark(question) } label: {
                                    Image(systemName: viewModel.study.bookmarks.contains(question.id) ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44)
                                }.accessibilityLabel("Toggle bookmark")
                            }
                            RichText(html: question.question, size: 16, weight: .semibold)
                            QuestionImage(url: question.imageURL)
                            ForEach(question.paragraphs) { block in
                                RichText(html: block.text)
                                QuestionImage(url: block.imageURL)
                            }
                            ForEach(question.answers) { answer in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: question.correct.contains(answer.id) ? "checkmark.circle.fill" : session.picks[question.id]?.contains(answer.id) == true ? "xmark.circle.fill" : "circle")
                                        .foregroundStyle(question.correct.contains(answer.id) ? Color.green : Color.slate)
                                    VStack(alignment: .leading, spacing: 8) {
                                        RichText(html: answer.text, size: 14)
                                        QuestionImage(url: answer.imageURL)
                                    }
                                }
                            }
                            if question.isEssay {
                                Text("Your response").font(.h(14))
                                if let essay = session.draft.essays[question.id], !essay.isEmpty {
                                    Text(essay).font(.subheadline)
                                } else {
                                    Text("No response").font(.subheadline)
                                }
                            }
                            ExplanationView(question: question)
                        }.card()
                    }
                }.padding(20)
            }
            .background(Color.bg).navigationTitle("Review answers").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private func status(_ question: Question) -> LocalizedStringKey {
        question.isEssay ? "Self-review · not scored" : !session.isAnswered(question) ? "Unanswered" : session.isCorrect(question) ? "Correct" : "Incorrect"
    }
}
