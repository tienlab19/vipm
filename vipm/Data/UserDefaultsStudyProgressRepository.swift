import Foundation

struct UserDefaultsStudyProgressRepository: StudyProgressRepository {
    let defaults: UserDefaults
    private let key = "studyProgress.v1"

    func load() throws -> StudyProgress {
        var progress: StudyProgress
        if let data = defaults.data(forKey: key) {
            progress = try JSONDecoder().decode(StudyProgress.self, from: data)
        } else { progress = StudyProgress() }
        if progress.learnerName == nil { progress.learnerName = defaults.string(forKey: "learnerName") }
        return progress
    }

    func save(_ progress: StudyProgress) throws {
        defaults.set(try JSONEncoder().encode(progress), forKey: key)
    }
}
