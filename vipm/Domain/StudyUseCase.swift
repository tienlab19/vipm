import Foundation

enum StudyPersistenceError: LocalizedError {
    case unreadable
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadable: "Saved progress could not be read. The original data has been preserved."
        case .saveFailed(let message): "Progress could not be saved: \(message)"
        }
    }
}

struct StudyUseCase {
    let bank: QuestionBank
    let isPremium: Bool
    let passBar = 0.85
    let examCount = 80
    let examMinutes = 60
    let flashCounts = [10, 20, 30]
    let timeTrialCount = 20
    let timeTrialMinutes = 5
    private let progressRepository: any StudyProgressRepository
    private(set) var progress: StudyProgress
    private(set) var persistenceError: StudyPersistenceError?
    /// Topics chosen in Topic Mastery, read when building its session.
    private(set) var pendingTopics: Set<String> = []

    init(bank: QuestionBank, progressRepository: any StudyProgressRepository, isPremium: Bool) {
        self.bank = bank
        self.progressRepository = progressRepository
        self.isPremium = isPremium
        do { progress = try progressRepository.load() }
        catch { progress = StudyProgress(); persistenceError = .unreadable }
    }

    var learnerName: String { progress.learnerName ?? "Scrum learner" }
    var bookmarks: Set<String> { progress.bookmarks.intersection(Set(bank.all.map(\.id))) }
    var answered: Set<String> { progress.answered.intersection(Set(bank.all.map(\.id))) }
    var wrong: Set<String> { progress.wrong.intersection(Set(bank.all.map(\.id))) }
    var missed: Set<String> { progress.missed.intersection(Set(bank.all.map(\.id))) }
    var completedAttempts: Int { progress.completedAttempts }
    var bestScore: Double { progress.bestScore }
    var unlockedQuestions: [Question] { bank.parts.filter { isPremium || !$0.isPremium }.flatMap(\.questions) }
    var examQuestions: [Question] { unlockedQuestions.filter { !$0.isEssay } }

    /// PSPO I form: 80 questions drawn across the focus areas in proportion to the bank, never repeating a question.
    func examForm() -> [Question] {
        let pools = bank.parts
            .filter { isPremium || !$0.isPremium }
            .map { $0.questions.filter { !$0.isEssay }.shuffled() }
            .filter { !$0.isEmpty }
        let total = pools.reduce(0) { $0 + $1.count }
        guard total > examCount else { return examQuestions.shuffled() }
        var taken = pools.map { min($0.count, Int((Double($0.count) / Double(total) * Double(examCount)).rounded())) }
        var index = 0
        while taken.reduce(0, +) != examCount {
            let short = taken.reduce(0, +) < examCount
            let slot = index % pools.count
            if short, taken[slot] < pools[slot].count { taken[slot] += 1 }
            else if !short, taken[slot] > 0 { taken[slot] -= 1 }
            index += 1
        }
        return zip(pools, taken).flatMap { $0.prefix($1) }.shuffled()
    }

    /// Flash Challenge: a quick pack of `count` random unlocked multiple-choice questions.
    func flashForm(count: Int) -> [Question] { Array(examQuestions.shuffled().prefix(max(1, count))) }

    /// Time Trial: a short set drawn at random, run against the clock.
    func timeTrialForm() -> [Question] { Array(examQuestions.shuffled().prefix(timeTrialCount)) }

    /// Topic Mastery: multiple-choice questions from the chosen parts.
    func topicQuestions(_ ids: Set<String>) -> [Question] {
        bank.parts.filter { ids.contains($0.id) && (isPremium || !$0.isPremium) }.flatMap { $0.questions.filter { !$0.isEssay } }
    }

    /// Parts a learner can pick from in Topic Mastery.
    var selectableTopics: [Part] { bank.parts.filter { isPremium || !$0.isPremium } }

    mutating func setPendingTopics(_ ids: Set<String>) { pendingTopics = ids }
    var readiness: Double {
        let graded = Set(unlockedQuestions.filter { !$0.isEssay }.map(\.id))
        return graded.isEmpty ? 0 : Double(answered.subtracting(wrong).intersection(graded).count) / Double(graded.count)
    }
    var latestDraft: QuizDraft? {
        progress.drafts.values.filter { isValid($0) }.max { $0.startedAt < $1.startedAt }
    }

    func draft(for key: String) -> QuizDraft? {
        guard let draft = progress.drafts[key], isValid(draft) else { return nil }
        return draft
    }

    func questions(with ids: Set<String>) -> [Question] { unlockedQuestions.filter { ids.contains($0.id) } }

    func breakdown(for session: QuizSession) -> [(name: String, value: Double)] {
        bank.parts.compactMap { part in
            let asked = session.gradedQuestions.filter { question in part.questions.contains { $0.id == question.id } }
            guard !asked.isEmpty else { return nil }
            return (part.name, Double(asked.filter(session.isCorrect).count) / Double(asked.count))
        }
    }

    mutating func updateLearnerName(_ name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        progress.learnerName = name.isEmpty ? "Scrum learner" : String(name.prefix(60))
        persist()
    }

    mutating func toggleBookmark(_ question: Question) {
        if progress.bookmarks.contains(question.id) { progress.bookmarks.remove(question.id) }
        else { progress.bookmarks.insert(question.id) }
        persist()
    }

    mutating func session(for key: String) -> QuizSession? {
        if let draft = progress.drafts[key], isValid(draft) {
            let byID = Dictionary(uniqueKeysWithValues: unlockedQuestions.map { ($0.id, $0) })
            return QuizSession(questions: draft.questionIDs.compactMap { byID[$0] }, draft: draft)
        }
        let questions: [Question]
        let title: String
        let minutes: Int?
        switch key {
        case "exam": questions = examForm(); title = "Practice Exam"; minutes = examMinutes
        case "timetrial": questions = timeTrialForm(); title = "Time Trial"; minutes = timeTrialMinutes
        case let k where k.hasPrefix("flash-"):
            questions = flashForm(count: Int(k.dropFirst(6)) ?? flashCounts[0]); title = "Flash Challenge"; minutes = nil
        case "topics": questions = topicQuestions(pendingTopics); title = "Topic Mastery"; minutes = nil
        case "wrong": questions = self.questions(with: wrong); title = "Incorrect"; minutes = nil
        case "bookmarks": questions = self.questions(with: bookmarks); title = "Bookmarks"; minutes = nil
        case "missed": questions = self.questions(with: missed); title = "Missed Questions"; minutes = nil
        default:
            guard let part = bank.parts.first(where: { $0.id == key }), isPremium || !part.isPremium else { return nil }
            questions = part.questions; title = part.name; minutes = nil
        }
        guard !questions.isEmpty else { return nil }
        let session = QuizSession(questions: questions, key: key, title: title, minutes: minutes)
        saveDraft(session)
        return session
    }

    mutating func retake(_ previous: QuizSession) -> QuizSession {
        let key = previous.draft.key
        let questions: [Question]
        let minutes: Int?
        switch key {
        case "exam": questions = examForm(); minutes = examMinutes
        case "timetrial": questions = timeTrialForm(); minutes = timeTrialMinutes
        case let k where k.hasPrefix("flash-"): questions = flashForm(count: Int(k.dropFirst(6)) ?? flashCounts[0]); minutes = nil
        default: questions = previous.questions; minutes = previous.deadline == nil ? nil : examMinutes
        }
        let next = QuizSession(questions: questions, key: key, title: previous.title, minutes: minutes)
        saveDraft(next)
        return next
    }

    mutating func saveDraft(_ session: QuizSession) {
        guard !session.finished else { return }
        progress.drafts[session.draft.key] = session.draft
        persist()
    }

    mutating func checkAnswer(_ session: inout QuizSession) {
        guard !session.finished, let question = session.current, session.canCheck(question) else { return }
        session.checkAnswer()
        record(question, session: session)
        saveDraft(session)
    }

    mutating func finish(_ session: inout QuizSession, at date: Date = .now) {
        guard !session.finished else { return }
        session.finish(at: date)
        for question in session.questions {
            if session.isAnswered(question) { record(question, session: session) }
            else { progress.missed.insert(question.id) }
        }
        progress.drafts.removeValue(forKey: session.draft.key)
        progress.completedAttempts += 1
        progress.bestScore = max(progress.bestScore, session.score)
        persist()
    }

    private mutating func record(_ question: Question, session: QuizSession) {
        guard session.isAnswered(question) else { return }
        progress.answered.insert(question.id)
        progress.missed.remove(question.id)
        if question.isEssay || session.isCorrect(question) { progress.wrong.remove(question.id) }
        else { progress.wrong.insert(question.id) }
    }

    private func isValid(_ draft: QuizDraft) -> Bool {
        let allowed = Set(unlockedQuestions.map(\.id))
        return !draft.questionIDs.isEmpty && draft.questionIDs.indices.contains(draft.index)
            && Set(draft.questionIDs).isSubset(of: allowed)
            && Set(draft.questionIDs).count == draft.questionIDs.count
    }

    private mutating func persist() {
        guard persistenceError == nil else { return }
        do { try progressRepository.save(progress) }
        catch { persistenceError = .saveFailed(error.localizedDescription) }
    }
}
