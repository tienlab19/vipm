import SwiftUI
import Combine

struct QuizHost: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    let key: String
    @Binding var path: [Route]
    @State private var quiz: QuizViewModel?
    @State private var loaded = false

    var body: some View {
        Group {
            if let quiz {
                QuizView(quiz: quiz, path: $path, retake: {
                    Track.log("quiz_retake", ["quiz_key": key])
                    self.quiz = viewModel.retake(quiz)
                }).id(quiz.session.draft.id)
            } else if loaded {
                VStack {
                    ContentUnavailableView("Nothing to review", systemImage: "tray", description: Text("Study a part, skip a question, or save a bookmark first."))
                    Button("Back") { dismiss() }.frame(minHeight: 44)
                }.background(Color.bg)
            } else { ProgressView() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if !loaded {
                quiz = viewModel.session(for: key)
                if let quiz { MarketingCapture.prime(quiz) }
                loaded = true
                Track.log(quiz == nil ? "quiz_unavailable" : "quiz_start",
                          ["quiz_key": key, "question_count": quiz?.session.questions.count ?? 0])
            }
        }
    }
}

struct QuizView: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let quiz: QuizViewModel
    private var session: QuizSession { quiz.session }
    @Binding var path: [Route]
    let retake: () -> Void
    @State private var now = Date()
    @State private var showExit = false
    @State private var showSubmit = false
    @State private var showNavigator = false
    @State private var showPaywall = false
    private var isExam: Bool { session.deadline != nil }
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if session.finished {
                ResultView(session: session, path: $path, retake: retake)
            } else if let question = session.current {
                VStack(spacing: 0) {
                    topBar(question)
                    ScrollView {
                        questionBody(question).padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 24)
                    }.id(question.id)
                }
                .background(Color.bg)
                .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar(question) }
            }
        }
        .navigationBarBackButtonHidden().toolbar(.hidden, for: .navigationBar)
        .onReceive(tick, perform: updateTime)
        .onAppear { updateTime(.now) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { updateTime(.now) }
            else { viewModel.saveDraft(quiz) }
        }
        .onDisappear { viewModel.saveDraft(quiz) }
        .overlay {
            if showExit {
                AppConfirmationDialog(
                    title: "Leave this attempt?",
                    message: session.deadline == nil
                        ? Text("Your answers and position will be saved.")
                        : Text("Your answers will be saved. The exam timer keeps running."),
                    primaryTitle: "Save and leave",
                    secondaryTitle: "Keep studying",
                    primaryAction: {
                        showExit = false
                        Track.log("quiz_exit", ["index": session.index, "answered": session.answeredCount, "is_exam": isExam])
                        viewModel.saveDraft(quiz)
                        dismiss()
                    },
                    secondaryAction: { showExit = false }
                ).transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if showSubmit {
                AppConfirmationDialog(
                    title: "Submit this attempt?",
                    message: Text("\(session.missedCount) unanswered. You can review explanations after submitting."),
                    primaryTitle: "Submit answers",
                    secondaryTitle: "Keep reviewing",
                    primaryAction: {
                        showSubmit = false
                        viewModel.finish(quiz)
                        Track.log("quiz_submit", ["is_exam": isExam, "score": Int((quiz.session.score * 100).rounded()),
                                                  "correct": quiz.session.correctCount, "graded": quiz.session.gradedQuestions.count,
                                                  "unanswered": quiz.session.missedCount, "elapsed_sec": Int(quiz.session.elapsed)])
                    },
                    secondaryAction: { showSubmit = false }
                ).transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: showExit)
        .animation(.easeOut(duration: 0.18), value: showSubmit)
        .onChange(of: showNavigator) { _, shown in if shown { Track.log("exam_navigator_open") } }
        .sheet(isPresented: $showNavigator) {
            ExamNavigator(session: session, jump: { quiz.jump(to: $0) }, submit: { showSubmit = true })
        }
        .sheet(isPresented: $showPaywall) { GoProView() }
        .task {
            guard MarketingCapture.isActive, MarketingCapture.screen == .navigator else { return }
            try? await Task.sleep(for: .milliseconds(500))
            showNavigator = true
        }
    }

    private func updateTime(_ date: Date) {
        guard !session.finished else { return }
        now = date
        viewModel.updateTime(date, for: quiz)
        if session.finished {
            Track.log("quiz_timeout", ["answered": session.answeredCount, "score": Int((session.score * 100).rounded())])
        }
    }

    private func topBar(_ question: Question) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { showExit = true } label: {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.slate2).frame(width: 44, height: 44)
                }.accessibilityLabel("Save and close quiz")
                ProgressView(value: session.progress).tint(.brand).scaleEffect(y: 2)
                    .accessibilityLabel("Question progress")
                if let remaining = session.remaining(at: now) {
                    let urgent = remaining <= 300
                    Label(hhmmss(remaining), systemImage: "clock").font(.h(13)).monospacedDigit()
                        .foregroundStyle(urgent ? Color(0xB91C1C) : Color(0xB45309)).padding(.horizontal, 10).padding(.vertical, 7)
                        .background(urgent ? Color(0xFFECEC) : Color(0xFFF6E8), in: .rect(cornerRadius: 9))
                        .accessibilityLabel("Time remaining \(hhmmss(remaining))")
                }
            }
            HStack {
                Text("Question \(session.index + 1) of \(session.questions.count)").font(.system(size: 12.5)).foregroundStyle(Color.slate)
                Spacer()
                if isExam {
                    Button {
                        quiz.toggleFlag(question)
                        Track.log("question_flag_toggle", ["flagged": session.flags.contains(question.id)])
                    } label: {
                        Label {
                            session.flags.contains(question.id) ? Text("Flagged") : Text("Flag")
                        } icon: {
                            Image(systemName: session.flags.contains(question.id) ? "flag.fill" : "flag")
                        }
                            .font(.system(size: 12.5, weight: .medium)).frame(minHeight: 44)
                    }
                    .tint(session.flags.contains(question.id) ? Color(0xB45309) : Color.brand)
                    .accessibilityLabel(session.flags.contains(question.id) ? Text("Remove flag for review") : Text("Flag for review"))
                }
                Button {
                    if viewModel.study.isPremium {
                        viewModel.toggleBookmark(question)
                        Track.log("bookmark_toggle", ["saved": viewModel.study.bookmarks.contains(question.id), "source": "quiz"])
                    } else {
                        showPaywall = true
                        Track.log("paywall_open", ["source": "bookmark"])
                    }
                } label: {
                    Label {
                        viewModel.study.bookmarks.contains(question.id) ? Text("Saved") : Text("Save")
                    } icon: {
                        Image(systemName: viewModel.study.isPremium
                              ? (viewModel.study.bookmarks.contains(question.id) ? "bookmark.fill" : "bookmark")
                              : "lock.fill")
                    }
                        .font(.system(size: 12.5, weight: .medium)).frame(minHeight: 44)
                }.accessibilityLabel(viewModel.study.bookmarks.contains(question.id) ? Text("Remove bookmark") : Text("Save question"))
            }
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 4)
        .background(.white).overlay(alignment: .bottom) { Divider() }
    }

    private func questionBody(_ question: Question) -> some View {
        let revealed = session.draft.checked.contains(question.id)
        return VStack(alignment: .leading, spacing: 16) {
            Group {
                if question.isEssay { Text("SELF-REVIEW · NOT SCORED") }
                else if question.isMulti { Text("MULTIPLE ANSWERS · PICK \(question.pickCount)") }
                else { Text("SINGLE ANSWER") }
            }
                .font(.system(size: 11, weight: .semibold)).kerning(0.4).foregroundStyle(Color.brand)
                .padding(.horizontal, 10).padding(.vertical, 5).background(Color.brandSoft, in: .rect(cornerRadius: 7))
            RichText(html: question.question, size: 18.5, weight: .semibold).foregroundStyle(Color.navy)
            QuestionImage(url: question.imageURL)
            ForEach(question.paragraphs) { block in
                RichText(html: block.text)
                QuestionImage(url: block.imageURL)
            }
            if question.isEssay {
                Text("Write your response, then compare it with the model answer.").font(.subheadline).foregroundStyle(Color.slate)
                TextEditor(text: Binding(get: { session.draft.essays[question.id] ?? "" }, set: { quiz.updateEssay($0, for: question) }))
                    .frame(minHeight: 140).padding(10).background(.white, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.hairline))
                    .accessibilityLabel("Your written response").disabled(revealed)
            } else {
                VStack(spacing: 11) {
                    ForEach(question.answers) { answer in option(question, answer: answer, revealed: revealed) }
                }
            }
            if revealed { ExplanationView(question: question) }
        }
    }

    private func option(_ question: Question, answer: Answer, revealed: Bool) -> some View {
        let picked = session.picks[question.id]?.contains(answer.id) == true
        let correct = question.correct.contains(answer.id)
        let highlighted = picked || (revealed && correct)
        let tint: Color = revealed ? (correct ? .green : picked ? .red : Color(0xE4EAF1)) : picked ? .brand : Color(0xE4EAF1)
        let fill: Color = revealed ? (correct ? Color(0xEAF7F1) : picked ? Color(0xFFF1F1) : .white) : picked ? .brandSoft : .white
        let content = Group {
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: question.isMulti ? 7 : 12).fill(highlighted ? tint : .clear)
                    RoundedRectangle(cornerRadius: question.isMulti ? 7 : 12).stroke(highlighted ? tint : Color(0xCBD5E1), lineWidth: 2)
                    if highlighted {
                        Image(systemName: revealed && picked && !correct ? "xmark" : "checkmark")
                            .font(.system(size: 11, weight: .black)).foregroundStyle(.white)
                    }
                }.frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 8) {
                    RichText(html: answer.text, size: 14)
                    QuestionImage(url: answer.imageURL, label: "Answer \(answer.id) illustration")
                }.foregroundStyle(Color.slate2)
            }
            .padding(15).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(fill, in: .rect(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(tint, lineWidth: 1.5))
            .shadow(color: Color.navy.opacity(highlighted ? 0.06 : 0.035), radius: 7, y: 3)
        }
        return Group {
            if revealed { content }
            else {
                Button {
                    quiz.toggle(answer.id, on: question)
                    Track.log("answer_select", ["is_multi": question.isMulti])
                } label: { content }.buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Answer \(answer.id). \(answer.text.plain)")
        .accessibilityValue(revealed ? (correct ? Text("Correct answer") : picked ? Text("Your incorrect answer") : Text("Not selected")) : picked ? Text("Selected") : Text("Not selected"))
        .accessibilityAddTraits(picked ? .isSelected : [])
        .accessibilityAddTraits(revealed ? .isStaticText : .isButton)
    }

    private func bottomBar(_ question: Question) -> some View {
        let revealed = session.draft.checked.contains(question.id)
        let needsCheck = session.deadline == nil && !revealed
        let title: LocalizedStringKey = needsCheck ? (question.isEssay ? "Reveal answer" : "Check answer") : session.isLast ? "Submit" : "Next"
        return VStack(spacing: 4) {
            if needsCheck {
                Button("Skip question") {
                    Track.log("question_skip", ["index": session.index])
                    if session.isLast { showSubmit = true } else { quiz.move(by: 1) }
                }.font(.subheadline).frame(minHeight: 44)
            }
            if isExam {
                Button {
                    showNavigator = true
                } label: {
                    Label("\(session.answeredCount) of \(session.questions.count) answered · Review", systemImage: "square.grid.3x3")
                        .font(.system(size: 13, weight: .medium))
                }.frame(minHeight: 44)
            }
            HStack(spacing: 12) {
                Button { quiz.move(by: -1) } label: {
                    Image(systemName: "chevron.left").frame(width: 54, height: 52).foregroundStyle(Color.slate2)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(0xE4EAF1)))
                }.disabled(session.index == 0).opacity(session.index == 0 ? 0.4 : 1).accessibilityLabel("Previous question")
                PrimaryButton(title: title, color: .navy) {
                    if needsCheck {
                        viewModel.checkAnswer(quiz)
                        Track.log("answer_check", ["correct": session.isCorrect(question)])
                    } else if session.isLast { showSubmit = true }
                    else { quiz.move(by: 1) }
                }
                .disabled(needsCheck && !session.canCheck(question))
                .opacity(needsCheck && !session.canCheck(question) ? 0.45 : 1)
            }
        }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 10).background(.white).overlay(alignment: .top) { Divider() }
    }
}

struct ExamNavigator: View {
    @Environment(\.dismiss) private var dismiss
    let session: QuizSession
    let jump: (Int) -> Void
    let submit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { index, question in
                        let answered = session.isAnswered(question)
                        let flagged = session.flags.contains(question.id)
                        Button {
                            jump(index)
                            Track.log("exam_navigator_jump", ["index": index])
                            dismiss()
                        } label: {
                            Text("\(index + 1)").font(.h(15)).monospacedDigit()
                                .foregroundStyle(answered ? .white : Color.slate2)
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(answered ? Color.brand : .white, in: .rect(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(flagged ? Color(0xB45309) : Color.hairline, lineWidth: flagged ? 2.5 : 1))
                                .overlay(alignment: .topTrailing) {
                                    if flagged {
                                        Image(systemName: "flag.fill").font(.system(size: 9))
                                            .foregroundStyle(Color(0xB45309)).padding(4)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Question \(index + 1)")
                        .accessibilityValue((answered ? Text("Answered") : Text("Unanswered")) + (flagged ? Text(", flagged") : Text(verbatim: "")))
                    }
                }.padding(20)
                VStack(spacing: 10) {
                    Text("\(session.answeredCount) answered · \(session.missedCount) unanswered · \(session.flags.count) flagged")
                        .font(.system(size: 13)).foregroundStyle(Color.slate)
                    PrimaryButton(title: "Submit exam", color: .navy) {
                        Track.log("exam_submit_tap", ["answered": session.answeredCount, "flagged": session.flags.count])
                        dismiss()
                        submit()
                    }
                }.padding(.horizontal, 20).padding(.bottom, 24)
            }
            .background(Color.bg).navigationTitle("Question map").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
        }
    }
}

struct ExplanationView: View {
    let question: Question
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            (question.isEssay ? Text("Model answer · self-review") : Text("Explanation")).font(.h(14))
            if question.isEssay {
                RichText(html: question.essayAnswer, size: 14)
                QuestionImage(url: question.essayImageURL, label: "Model answer illustration")
            }
            RichText(html: question.explanation, size: 14)
            ForEach(question.explanationParagraphs) { block in
                RichText(html: block.text, size: 14)
                QuestionImage(url: block.imageURL, label: "Explanation illustration")
            }
        }.foregroundStyle(Color.slate2).frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
