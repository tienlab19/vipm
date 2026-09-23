import Foundation

enum MarketingCaptureScreen: String {
    case home
    case practice
    case question
    case explanation
    case exam
    case navigator
    case results
    case profile
    case paywall
}

enum MarketingCapture {
    static var isActive: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-MarketingCapture")
        #else
        false
        #endif
    }

    static var screen: MarketingCaptureScreen {
        MarketingCaptureScreen(rawValue: argument(after: "-MarketingScreen") ?? "home") ?? .home
    }

    static var practicePartKey: String {
        argument(after: "-MarketingRoute") ?? "-Ng-WNrdl0nSTizDrKra"
    }

    static var initialRoute: [Route] {
        guard isActive else { return [] }
        return switch screen {
        case .question, .explanation: [.quiz(practicePartKey)]
        case .navigator, .results: [.quiz("exam")]
        default: []
        }
    }

    static func studyViewModel(reminderScheduler: (any ExamReminderScheduling)?) -> StudyViewModel {
        guard isActive,
              let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
              let bank = try? JSONQuestionBankRepository(url: url).load()
        else {
            return makeStudyViewModel(reminderScheduler: reminderScheduler)
        }

        return StudyViewModel(
            bankRepository: MarketingQuestionBankRepository(bank: bank),
            progressRepository: MarketingProgressRepository(progress: progress(for: bank)),
            isPremium: true,
            reminderScheduler: reminderScheduler
        )
    }

    static func prime(_ quiz: QuizViewModel) {
        guard isActive else { return }
        var session = quiz.session

        switch screen {
        case .explanation:
            guard let question = session.current else { return }
            session.draft.picks[question.id] = question.correct
            session.draft.checked.insert(question.id)
            quiz.update(session)
        case .results:
            session.draft.picks = [:]
            session.draft.checked = []
            for (index, question) in session.questions.enumerated() where !question.isEssay {
                session.draft.picks[question.id] = index < 72 ? question.correct : wrongSelection(for: question)
            }
            session.finish(at: .now)
            quiz.update(session)
        default:
            break
        }
    }

    private static func progress(for bank: QuestionBank) -> StudyProgress {
        let questions = bank.all
        var progress = StudyProgress()
        progress.learnerName = "Alex Morgan"
        progress.plannedExamDate = Calendar.current.date(byAdding: .day, value: 24, to: .now)
        progress.answered = Set(questions.prefix(680).map(\.id))
        progress.wrong = Set(questions.dropFirst(100).prefix(30).map(\.id))
        progress.missed = Set(questions.dropFirst(700).prefix(8).map(\.id))
        progress.bookmarks = Set(questions.dropFirst(40).prefix(12).map(\.id))
        progress.completedAttempts = 14
        progress.bestScore = 0.91

        if let part = bank.parts.first, !part.questions.isEmpty {
            let captureIndex = part.questions.enumerated()
                .filter { !$0.element.isEssay && $0.element.answers.count <= 3 }
                .min { lhs, rhs in
                    lhs.element.question.count + lhs.element.explanation.count
                        < rhs.element.question.count + rhs.element.explanation.count
                }?.offset ?? 0
            var practice = QuizDraft(
                key: part.id,
                title: part.name,
                questionIDs: part.questions.map(\.id),
                startedAt: Date().addingTimeInterval(-9 * 60),
                deadline: nil
            )
            practice.index = captureIndex
            progress.drafts[part.id] = practice
        }

        let examQuestions = Array(questions.filter { !$0.isEssay }.prefix(80))
        if !examQuestions.isEmpty {
            let startedAt = Date().addingTimeInterval(-37 * 60)
            var exam = QuizDraft(
                key: "exam",
                title: "Practice Exam",
                questionIDs: examQuestions.map(\.id),
                startedAt: startedAt,
                deadline: startedAt.addingTimeInterval(60 * 60)
            )
            for (index, question) in examQuestions.prefix(24).enumerated() {
                exam.picks[question.id] = index.isMultiple(of: 6) ? wrongSelection(for: question) : question.correct
            }
            exam.flags = Set(examQuestions.dropFirst(4).prefix(4).map(\.id))
            exam.index = 23
            progress.drafts["exam"] = exam
        }

        return progress
    }

    private static func wrongSelection(for question: Question) -> Set<Int> {
        let desiredCount = max(1, question.pickCount)
        var selected = Array(question.answers.map(\.id).filter { !question.correct.contains($0) }.prefix(desiredCount))
        if selected.count < desiredCount {
            selected.append(contentsOf: question.answers.map(\.id).filter { !selected.contains($0) }.prefix(desiredCount - selected.count))
        }
        let result = Set(selected)
        if result != question.correct { return result }
        return Set(question.answers.map(\.id).reversed().prefix(desiredCount))
    }

    private static func argument(after name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

private struct MarketingQuestionBankRepository: QuestionBankRepository {
    let bank: QuestionBank
    func load() throws -> QuestionBank { bank }
}

private final class MarketingProgressRepository: StudyProgressRepository {
    private var progress: StudyProgress

    init(progress: StudyProgress) {
        self.progress = progress
    }

    func load() throws -> StudyProgress { progress }
    func save(_ progress: StudyProgress) throws { self.progress = progress }
}
