import Observation

@Observable
final class QuizViewModel {
    private(set) var session: QuizSession
    private let onChange: (QuizSession) -> Void

    init(session: QuizSession, onChange: @escaping (QuizSession) -> Void) {
        self.session = session
        self.onChange = onChange
    }

    func toggle(_ option: Int, on question: Question) { session.toggle(option, on: question); onChange(session) }
    func move(by offset: Int) { session.move(by: offset); onChange(session) }
    func jump(to index: Int) { session.jump(to: index); onChange(session) }
    func toggleFlag(_ question: Question) { session.toggleFlag(question); onChange(session) }
    func updateEssay(_ text: String, for question: Question) { session.updateEssay(text, for: question); onChange(session) }
    func update(_ session: QuizSession) { self.session = session }
}
