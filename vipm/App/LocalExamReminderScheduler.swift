import Foundation
import UserNotifications

struct LocalExamReminderScheduler: ExamReminderScheduling {
    private let identifiers = ["exam-reminder-7", "exam-reminder-3", "exam-reminder-1", "exam-reminder-0"]

    func schedule(for examDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Track.log("exam_reminder_permission", ["granted": granted])
            guard granted else { return }
            let calendar = Calendar.current
            let examDay = calendar.startOfDay(for: examDate)
            let reminders: [(days: Int, hour: Int, body: String)] = [
                (7, 9, String(localized: "Your planned exam is in one week. Keep practicing.")),
                (3, 9, String(localized: "Your planned exam is in 3 days. Review missed questions.")),
                (1, 9, String(localized: "Your planned exam is tomorrow. You are almost there.")),
                (0, 7, String(localized: "Your planned exam is today. Good luck!"))
            ]
            var scheduled = 0
            for reminder in reminders {
                guard let day = calendar.date(byAdding: .day, value: -reminder.days, to: examDay),
                      let fireDate = calendar.date(bySettingHour: reminder.hour, minute: 0, second: 0, of: day),
                      fireDate > .now else { continue }
                let content = UNMutableNotificationContent()
                content.title = String(localized: "PSPO I exam reminder")
                content.body = reminder.body
                content.sound = .default
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let request = UNNotificationRequest(
                    identifier: "exam-reminder-\(reminder.days)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                center.add(request)
                scheduled += 1
            }
            Track.log("exam_reminders_scheduled", ["count": scheduled])
        }
    }
}
