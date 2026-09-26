import Foundation

enum Track {
    static func log(_ event: String, _ parameters: [String: Any] = [:]) {}
}

@main
struct SelfCheck {
    @MainActor
    static func main() async throws {
        let input = URL(fileURLWithPath: CommandLine.arguments[1])
        let bank = try JSONQuestionBankRepository(url: input).load()
        assert(bank.isDemo && bank.parts.count == 1 && bank.parts[0].questions.count == 2)
        let appBank = try JSONQuestionBankRepository(url: URL(fileURLWithPath: CommandLine.arguments[2])).load()
        assert(!appBank.parts.isEmpty && !appBank.all.isEmpty, "The bundled question bank must decode.")
        assert(AppFeatures.inAppPurchasesEnabled, "Premium purchases must remain enabled.")
        assert(PremiumStore.productID == "com.viuniverse.pspo.one.premium",
               "Release Product ID must match App Store Connect.")
        assert(AppFeatures.shouldShowAds(isPremium: false), "Free users should be eligible for ads.")
        assert(!AppFeatures.shouldShowAds(isPremium: true), "Premium must be ad-free.")
        assert(AppFeatures.canRequestAds(isPremium: false, consentAllowsAds: true))
        assert(!AppFeatures.canRequestAds(isPremium: false, consentAllowsAds: false))
        assert(!AppFeatures.canRequestAds(isPremium: true, consentAllowsAds: true),
               "Premium must stay ad-free even when consent allows ads.")
        assert(AppFeatures.shouldShowExamResultInterstitial(isPremium: false, isExam: true))
        assert(!AppFeatures.shouldShowExamResultInterstitial(isPremium: false, isExam: false))
        assert(!AppFeatures.shouldShowExamResultInterstitial(isPremium: true, isExam: true))
        let freeApp = StudyUseCase(bank: appBank, progressRepository: MemoryProgressRepository(), isPremium: false)
        let premiumApp = StudyUseCase(bank: appBank, progressRepository: MemoryProgressRepository(), isPremium: true)
        assert(freeApp.unlockedQuestions.count == freeApp.freeQuestionLimit && freeApp.freeQuestionLimit == 30)
        assert(premiumApp.unlockedQuestions.count == appBank.all.count && appBank.all.count == 800)
        let single = bank.parts[0].questions[0]
        let multi = bank.parts[0].questions[1]
        assert(single.correct == [2] && multi.correct == [1, 3])

        var session = QuizSession(questions: [single, multi], title: "Check")
        session.toggle(2, on: single)
        assert(session.isCorrect(single))
        session.toggle(1, on: multi)
        assert(!session.isCorrect(multi) && !session.canCheck(multi))
        session.toggle(3, on: multi)
        assert(session.isCorrect(multi) && session.score == 1)
        session.toggle(4, on: multi)
        assert(session.picks[multi.id] == [1, 3], "Selection count is capped.")
        session.toggle(3, on: multi)
        session.toggle(4, on: multi)
        assert(!session.isCorrect(multi) && session.wrongCount == 1)
        session.move(by: 99)
        assert(session.index == 1)
        session.move(by: -99)
        assert(session.index == 0)
        session.toggle(99, on: single)
        assert(session.picks[single.id] == [2], "Unknown answer IDs are ignored.")
        session.toggle(2, on: single)
        assert(session.picks[single.id]?.isEmpty == true, "Single-choice answers can be deselected.")

        let sparse = try decodeQuestion([
            "question": "<p>Pick the eighth answer.</p>", "answer_1": "No", "answer_8": "Yes",
            "correct_answer": "8", "is_multi_choices": "0", "is_question_essay": false,
            "paragraph_4": "Context", "paragraph_10_of_explanation": "Final explanation"
        ])
        assert(sparse.answers.map(\.id) == [1, 8] && sparse.correct == [8])
        assert(sparse.paragraphs.count == 1 && sparse.explanationParagraphs.count == 1)
        let image = try decodeQuestion([
            "question": "Choose an image", "is_answer_image": 1,
            "image_url_at_answer_1": "https://example.com/a.png", "image_url_at_answer_2": "https://example.com/b.png",
            "correct_answer": 2
        ])
        assert(image.answers.count == 2 && image.answers[0].imageURL != nil)
        let flexibleMulti = try decodeQuestion([
            "question": "Two answers", "answer_1": "First", "answer_8": "Last",
            "is_multi_choices": true, "how_many_choices": "2", "correct_answers": "1, 8"
        ])
        assert(flexibleMulti.isMulti && flexibleMulti.correct == [1, 8] && flexibleMulti.pickCount == 2)
        for invalid in [
            ["question": "Bad key", "answer_1": "A", "answer_2": "B", "correct_answer": 8],
            ["question": "Bad CSV", "answer_1": "A", "answer_2": "B", "is_multi_choices": 1, "correct_answers": "1,no"],
            ["question": "Duplicate CSV", "answer_1": "A", "answer_2": "B", "is_multi_choices": 1, "correct_answers": "1,1"],
            ["question": "Unsafe URL", "answer_1": "A", "answer_2": "B", "correct_answer": 1, "image_url": "file:///etc/passwd"],
            ["question": "Bad flag", "answer_1": "A", "answer_2": "B", "correct_answer": 1, "is_multi_choices": 7]
        ] as [[String: Any]] {
            do { _ = try decodeQuestion(invalid); assertionFailure("Invalid question accepted") }
            catch {}
        }

        var essay = try decodeQuestion(["question": "Explain your reasoning.", "is_question_essay": "1", "answer_for_essay": "Model"])
        essay.id = "essay"
        var mixed = QuizSession(questions: [single, essay], title: "Self-review")
        mixed.toggle(2, on: single)
        mixed.updateEssay("   ", for: essay)
        assert(!mixed.isAnswered(essay), "Whitespace is not an essay response.")
        mixed.updateEssay("My response", for: essay)
        assert(mixed.gradedQuestions.count == 1 && mixed.score == 1 && !mixed.isCorrect(essay))
        mixed.move(by: 1)
        mixed.checkAnswer()
        mixed.updateEssay("Changed", for: essay)
        assert(mixed.draft.essays[essay.id] == "My response", "Checked essays stay locked.")
        let empty = QuizSession(questions: [], title: "Empty")
        assert(empty.score == 0 && empty.current == nil && empty.progress == 0)

        let start = Date(timeIntervalSince1970: 1_000)
        var timed = QuizSession(questions: [single, multi], title: "Timed", minutes: 1, startedAt: start)
        assert(timed.remaining(at: start) == 60)
        assert(timed.remaining(at: start.addingTimeInterval(59.1)) == 1)
        assert(timed.remaining(at: start.addingTimeInterval(61)) == 0)
        timed.finish(at: start.addingTimeInterval(120))
        assert(timed.elapsed == 60 && timed.finished && timed.missedCount == 2)
        timed.finish(at: start.addingTimeInterval(200))
        timed.toggle(2, on: single)
        timed.jump(to: 1)
        timed.toggleFlag(single)
        assert(timed.elapsed == 60 && timed.picks.isEmpty)
        assert(timed.index == 0 && timed.flags.isEmpty, "Finished sessions are immutable.")

        let export: [String: Any] = [
            "config": ["module_title": "Export", "updated_time": "Fixture"],
            "modules": ["-Ng-ViDLQtXSAAAFYzJA": ["quiz_parts": [
                "part": ["name": "Part", "is_premium": "1", "how_many_questions": "999", "questions": [
                    "question": ["question": "Pick one", "answer_1": "A", "answer_2": "B", "correct_answer": 1]
                ]]
            ]]]
        ]
        let exportBank = try JSONDecoder().decode(QuestionBankDTO.self, from: JSONSerialization.data(withJSONObject: export)).value
        assert(!exportBank.isDemo && exportBank.parts[0].isPremium && exportBank.parts[0].questions.count == 1)
        assert(exportBank.parts[0].questions[0].id == "part/question")

        let memory = MemoryProgressRepository()
        let viewModel = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: memory, isPremium: false)
        guard let practice = viewModel.session(for: "examples") else { fatalError("Cannot create practice") }
        practice.toggle(2, on: single)
        assert(memory.progress.drafts["examples"]?.picks[single.id] == [2], "ViewModel actions save without a View lifecycle.")
        viewModel.toggleBookmark(single)
        assert(memory.progress.bookmarks.isEmpty, "Bookmarks are Premium-only.")
        viewModel.setPremium(true)
        viewModel.toggleBookmark(single)
        let restored = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: memory, isPremium: true)
        guard let resumed = restored.session(for: "examples") else { fatalError("Cannot resume") }
        assert(resumed.session.picks[single.id] == [2] && restored.study.bookmarks.contains(single.id))
        restored.finish(resumed)
        assert(restored.study.answered == [single.id] && restored.study.missed == [multi.id] && restored.study.wrong.isEmpty)
        assert(restored.study.completedAttempts == 1 && restored.study.latestDraft == nil)
        restored.finish(resumed)
        assert(restored.study.completedAttempts == 1, "Submit must be idempotent.")
        guard let retry = restored.retake(resumed) else { fatalError("Cannot retake free practice") }
        assert(retry.session.draft.id != resumed.session.draft.id && retry.session.picks.isEmpty && !retry.session.finished)
        assert(memory.progress.drafts["examples"]?.id == retry.session.draft.id)
        let immutableResult = resumed.session
        retry.toggle(1, on: single)
        assert(immutableResult.picks[single.id] == [2], "Retakes must not mutate the result snapshot.")
        restored.checkAnswer(retry)
        assert(retry.session.draft.checked.contains(single.id) && restored.study.wrong.contains(single.id))
        retry.toggle(2, on: single)
        assert(retry.session.picks[single.id] == [1], "Checked answers stay locked.")

        var firstQuestion = single
        firstQuestion.id = "first/q1"
        var secondQuestion = single
        secondQuestion.id = "second/q1"
        let scoredBank = QuestionBank(title: "Scored", updatedTime: "", parts: [
            Part(id: "first", name: "First", isPremium: false, questions: [firstQuestion]),
            Part(id: "second", name: "Second", isPremium: false, questions: [secondQuestion])
        ], isDemo: false)
        var scoredUseCase = StudyUseCase(bank: scoredBank, progressRepository: MemoryProgressRepository(), isPremium: false)
        var scoredSession = QuizSession(questions: [firstQuestion, secondQuestion], title: "Scored")
        scoredSession.toggle(2, on: firstQuestion)
        scoredSession.toggle(1, on: secondQuestion)
        scoredUseCase.finish(&scoredSession)
        let breakdown = scoredUseCase.breakdown(for: scoredSession)
        assert(scoredUseCase.readiness == 0.5 && scoredUseCase.bestScore == 0.5)
        assert(breakdown.count == 2 && breakdown[0].value == 1 && breakdown[1].value == 0)
        assert(scoredUseCase.questions(with: [secondQuestion.id, firstQuestion.id]).map(\.id) == [firstQuestion.id, secondQuestion.id])

        let timeoutMemory = MemoryProgressRepository()
        let timeoutModel = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: timeoutMemory, isPremium: false)
        guard let exam = timeoutModel.session(for: "exam"), let deadline = exam.session.deadline else { fatalError("Cannot start exam") }
        timeoutModel.updateTime(deadline.addingTimeInterval(15), for: exam)
        assert(exam.session.finished && exam.session.elapsed == 3_600 && timeoutModel.study.completedAttempts == 1)
        timeoutModel.updateTime(deadline.addingTimeInterval(30), for: exam)
        assert(timeoutModel.study.completedAttempts == 1)
        assert(timeoutModel.session(for: "flash-10") == nil)
        assert(timeoutModel.session(for: "timetrial") == nil)

        let premiumModesProgress = MemoryProgressRepository()
        premiumModesProgress.progress.bookmarks = [single.id]
        premiumModesProgress.progress.wrong = [single.id]
        var premiumModes = StudyUseCase(bank: bank, progressRepository: premiumModesProgress, isPremium: false)
        assert(premiumModes.bookmarks.isEmpty)
        assert(premiumModes.session(for: "bookmarks") == nil && premiumModes.session(for: "wrong") == nil)
        premiumModes.setPremium(true)
        assert(premiumModes.session(for: "bookmarks") != nil && premiumModes.session(for: "wrong") != nil)
        assert(premiumModes.session(for: "flash-10") != nil && premiumModes.session(for: "timetrial") != nil)
        guard let flash = premiumModes.session(for: "flash-10") else { fatalError("Cannot start Premium flash") }
        premiumModes.setPremium(false)
        assert(premiumModes.retake(flash) == nil, "Premium modes must re-check entitlement before retake.")

        var locked = StudyUseCase(bank: exportBank, progressRepository: MemoryProgressRepository(), isPremium: false)
        var unlocked = StudyUseCase(bank: exportBank, progressRepository: MemoryProgressRepository(), isPremium: true)
        assert(locked.unlockedQuestions.isEmpty && locked.session(for: "part") == nil)
        assert(unlocked.unlockedQuestions.count == 1 && unlocked.session(for: "part") != nil)
        locked.setPremium(true)
        assert(locked.unlockedQuestions.count == 1 && locked.session(for: "part") != nil)
        locked.setPremium(false)
        assert(locked.unlockedQuestions.isEmpty, "Revoked Premium access locks paid questions again.")

        let quotaBank = QuestionBank(title: "Quota", updatedTime: "", parts: [
            Part(id: "free", name: "Free", isPremium: false, questions: (1...35).map { number in
                var question = single
                question.id = "free/\(number)"
                return question
            }),
            Part(id: "premium", name: "Premium", isPremium: true, questions: (1...5).map { number in
                var question = single
                question.id = "premium/\(number)"
                return question
            })
        ], isDemo: false)
        var quota = StudyUseCase(bank: quotaBank, progressRepository: MemoryProgressRepository(), isPremium: false)
        assert(quota.unlockedQuestions.count == 30)
        assert(quota.session(for: "free")?.questions.count == 30 && quota.session(for: "premium") == nil)
        quota.setPremium(true)
        guard let paidSession = quota.session(for: "premium") else { fatalError("Cannot start Premium practice") }
        quota.setPremium(false)
        assert(quota.retake(paidSession) == nil, "Retake must re-check the current Premium entitlement.")

        let suite = "vipm.selfcheck.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Test defaults unavailable") }
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy: [String: Any] = [
            "bookmarks": [single.id], "answered": [single.id], "wrong": [], "missed": [multi.id],
            "drafts": ["examples": [
                "id": "0D54F422-88AA-4380-8C8C-BDA76C04855F", "key": "examples", "title": "Legacy quiz",
                "questionIDs": [single.id, multi.id], "startedAt": 1_000, "index": 1,
                "picks": [single.id: [2]], "essays": [:], "checked": [single.id]
            ]], "completedAttempts": 4, "bestScore": 0.5
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: "studyProgress.v1")
        defaults.set("Existing learner", forKey: "learnerName")
        let repository = UserDefaultsStudyProgressRepository(defaults: defaults)
        let legacyModel = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: repository, isPremium: false)
        guard let legacyQuiz = legacyModel.session(for: "examples") else { fatalError("Legacy draft lost") }
        assert(legacyModel.study.learnerName == "Existing learner" && legacyModel.study.completedAttempts == 4)
        assert(legacyQuiz.session.index == 1 && legacyQuiz.session.draft.checked == [single.id])
        assert(legacyQuiz.session.picks[single.id] == [2] && legacyModel.study.bookmarks.isEmpty)
        legacyModel.setPremium(true)
        assert(legacyModel.study.bookmarks == [single.id], "Stored bookmarks reappear after Premium is restored.")
        legacyQuiz.toggle(1, on: multi)
        let persisted = try repository.load()
        assert(persisted.drafts["examples"]?.picks[multi.id] == [1] && persisted.bestScore == 0.5)
        legacyModel.updateLearnerName("  Refactored learner  ")
        let renamed = try repository.load()
        assert(renamed.learnerName == "Refactored learner")
        legacyModel.updateLearnerName("   ")
        assert(legacyModel.study.learnerName == "Scrum learner")
        let examDate = Date(timeIntervalSince1970: 1_800_000_000)
        legacyModel.updateExamProfile(name: "  Exam candidate  ", plannedExamDate: examDate)
        let examProfile = try repository.load()
        assert(examProfile.learnerName == "Exam candidate")
        assert(examProfile.plannedExamDate == Calendar.current.startOfDay(for: examDate))

        let scheduler = SpyExamReminderScheduler()
        let profileMemory = MemoryProgressRepository()
        let profileModel = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: profileMemory,
                                          isPremium: false, reminderScheduler: scheduler)
        profileModel.updateExamProfile(name: String(repeating: "A", count: 80), plannedExamDate: examDate)
        assert(profileModel.study.learnerName.count == 60)
        assert(profileMemory.progress.plannedExamDate == Calendar.current.startOfDay(for: examDate))
        assert(scheduler.examDates == [examDate], "Saving the exam plan schedules reminders.")

        let invalidDrafts = MemoryProgressRepository()
        invalidDrafts.progress.drafts = [
            "empty": QuizDraft(key: "empty", title: "Empty", questionIDs: [], startedAt: start, deadline: nil),
            "duplicate": QuizDraft(key: "duplicate", title: "Duplicate", questionIDs: [single.id, single.id], startedAt: start, deadline: nil),
            "topics": QuizDraft(key: "topics", title: "Old route", questionIDs: [single.id], startedAt: start, deadline: nil)
        ]
        invalidDrafts.progress.drafts["invalid-index"] = QuizDraft(
            key: "invalid-index", title: "Invalid index", questionIDs: [single.id], startedAt: start, deadline: nil, index: 2
        )
        let draftValidator = StudyUseCase(bank: bank, progressRepository: invalidDrafts, isPremium: true)
        assert(draftValidator.draft(for: "empty") == nil)
        assert(draftValidator.draft(for: "duplicate") == nil)
        assert(draftValidator.draft(for: "topics") == nil)
        assert(draftValidator.draft(for: "invalid-index") == nil)

        for localFlag in [false, true] {
            defaults.set(localFlag, forKey: "premium")
            let composed = makeStudyViewModel(defaults: defaults)
            assert(composed.bankError == nil && composed.study.bank.all.count == 2)
            assert(!composed.study.isPremium, "Launch access follows verified StoreKit entitlement, never a saved Premium flag.")
            assert(composed.session(for: "timetrial") == nil)
            assert(composed.session(for: "bookmarks") == nil)
        }
        let corrupt = Data("broken".utf8)
        defaults.set(corrupt, forKey: "studyProgress.v1")
        let recovery = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: repository, isPremium: true)
        recovery.toggleBookmark(single)
        assert(recovery.persistenceError != nil && defaults.data(forKey: "studyProgress.v1") == corrupt)

        let failing = MemoryProgressRepository()
        failing.failSaves = true
        let failingModel = StudyViewModel(bankRepository: FixtureBankRepository(bank: bank), progressRepository: failing, isPremium: true)
        failingModel.toggleBookmark(single)
        assert(failingModel.persistenceError != nil && failing.progress.bookmarks.isEmpty)
        assert(failingModel.study.bookmarks.contains(single.id), "Save errors keep in-memory progress available.")
        let unreadable = MemoryProgressRepository()
        unreadable.failLoads = true
        var unreadableUseCase = StudyUseCase(bank: bank, progressRepository: unreadable, isPremium: true)
        unreadableUseCase.updateLearnerName("Not persisted")
        assert(unreadableUseCase.persistenceError != nil && unreadable.progress.learnerName == nil)
        let big = QuestionBank(title: "Exam", updatedTime: "", parts: (1...4).map { part in
            Part(id: "p\(part)", name: "Focus \(part)", isPremium: false, questions: (1...(part * 40)).map { number in
                var question = single
                question.id = "p\(part)/q\(number)"
                return question
            })
        }, isDemo: false)
        var examUse = StudyUseCase(bank: big, progressRepository: MemoryProgressRepository(), isPremium: true)
        let form = examUse.examForm()
        assert(form.count == examUse.examCount && Set(form.map(\.id)).count == form.count, "A form is 80 distinct questions.")
        assert(Set(form.map(\.id)).isSubset(of: Set(examUse.examQuestions.map(\.id))), "A form only uses the unlocked global pool.")
        assert(examUse.examForm().map(\.id) != form.map(\.id), "Each attempt draws a new form.")
        guard var examSession = examUse.session(for: "exam") else { fatalError("Cannot start exam") }
        assert(examSession.questions.count == examUse.examCount && examSession.answeredCount == 0)
        examSession.jump(to: 41)
        examSession.toggle(2, on: examSession.questions[41])
        examSession.toggleFlag(examSession.questions[41])
        assert(examSession.index == 41 && examSession.answeredCount == 1 && examSession.flags.count == 1)
        examSession.toggleFlag(examSession.questions[41])
        examSession.jump(to: 999)
        assert(examSession.flags.isEmpty && examSession.index == 41, "Flags toggle off and jumps stay in range.")
        examUse.saveDraft(examSession)
        guard let resumedExam = examUse.session(for: "exam") else { fatalError("Cannot resume exam") }
        assert(resumedExam.index == 41 && resumedExam.answeredCount == 1, "Position and answers survive a resume.")
        examUse.finish(&examSession)
        assert(examSession.missedCount == 79 && examSession.score < examUse.passBar)
        guard let retakenExam = examUse.retake(examSession) else { fatalError("Cannot retake exam") }
        assert(retakenExam.questions.map(\.id) == examSession.questions.map(\.id), "Retaking an exam keeps the same form and order.")
        assert(retakenExam.deadline != nil && retakenExam.picks.isEmpty, "Retaking resets answers and the 60-minute timer.")

        let missing = StudyViewModel(bankRepository: JSONQuestionBankRepository(url: nil), progressRepository: MemoryProgressRepository(), isPremium: false)
        assert(missing.bankError != nil && missing.study.bank.all.isEmpty && missing.session(for: "exam") == nil)
        print("PASS: parsing, scoring, essays, drafts, persistence, reminders, premium gates, practice modes, exam, resume, retake, timeout, view models, dependency injection")
    }

    static func decodeQuestion(_ fields: [String: Any]) throws -> Question {
        try JSONDecoder().decode(QuestionDTO.self, from: JSONSerialization.data(withJSONObject: fields)).value
    }
}

private struct FixtureBankRepository: QuestionBankRepository {
    let bank: QuestionBank
    func load() throws -> QuestionBank { bank }
}

private final class MemoryProgressRepository: StudyProgressRepository {
    var progress = StudyProgress()
    var failLoads = false
    var failSaves = false

    func load() throws -> StudyProgress {
        if failLoads { throw CocoaError(.fileReadCorruptFile) }
        return progress
    }
    func save(_ progress: StudyProgress) throws {
        if failSaves { throw CocoaError(.fileWriteUnknown) }
        self.progress = progress
    }
}

private final class SpyExamReminderScheduler: ExamReminderScheduling {
    private(set) var examDates: [Date] = []
    func schedule(for examDate: Date) { examDates.append(examDate) }
}
