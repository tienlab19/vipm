import SwiftUI

struct ExamProfileSetupView: View {
    let isOnboarding: Bool
    let onSave: (String, Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var examDate: Date

    init(name: String, examDate: Date?, isOnboarding: Bool, onSave: @escaping (String, Date) -> Void) {
        self.isOnboarding = isOnboarding
        self.onSave = onSave
        let today = Calendar.current.startOfDay(for: .now)
        let defaultDate = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        _name = State(initialValue: name == "Scrum learner" ? "" : name)
        _examDate = State(initialValue: max(examDate.map { Calendar.current.startOfDay(for: $0) } ?? defaultDate, today))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if !isOnboarding {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                }
                Spacer()
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 34, weight: .semibold)).foregroundStyle(Color.brand)
                        .frame(width: 72, height: 72).background(Color.brandSoft, in: .rect(cornerRadius: 20))
                    Text(isOnboarding ? "Set your exam goal" : "Exam plan")
                        .font(.h(28, .bold)).foregroundStyle(Color.navy)
                    Text("Tell us your name and planned exam date. We will remind you as the date gets closer.")
                        .font(.system(size: 14)).foregroundStyle(Color.slate2)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Candidate name").font(.h(14))
                        TextField("Your name", text: $name)
                            .textContentType(.name).submitLabel(.done)
                            .padding(16).background(Color.white, in: .rect(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.hairline))
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Planned exam date").font(.h(14))
                        DatePicker("Planned exam date", selection: $examDate,
                                   in: Calendar.current.startOfDay(for: .now)...,
                                   displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding(12).background(Color.white, in: .rect(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.hairline))
                    }

                    Label("Reminders are scheduled 7 days, 3 days, 1 day, and the morning of your exam.",
                          systemImage: "bell.badge")
                        .font(.caption).foregroundStyle(Color.slate2)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }

            PrimaryButton(title: isOnboarding ? "Save and continue" : "Save exam plan") {
                onSave(name, examDate)
                dismiss()
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .padding(.horizontal, 24).padding(.vertical, 16)
        }
        .background(Color.bg.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onAppear { Track.screen(isOnboarding ? "exam_profile_onboarding" : "exam_plan_editor") }
    }
}
