import SwiftUI

enum Route: Hashable {
    case practiceExam
    case parts
    case flashChallenge
    case topicMastery
    case quiz(String)
}

private enum MainTab: String, CaseIterable {
    case home = "Home", exam = "Exam", saved = "Saved", profile = "Profile"
    var icon: String {
        switch self {
        case .home: "house"
        case .exam: "checkmark.square"
        case .saved: "bookmark"
        case .profile: "person"
        }
    }
    var title: LocalizedStringKey {
        switch self {
        case .home: "Home"
        case .exam: "Exam"
        case .saved: "Saved"
        case .profile: "Profile"
        }
    }
}

struct HomeView: View {
    @Environment(StudyViewModel.self) private var viewModel
    @State private var tab = MainTab.home
    @State private var path: [Route] = []
    @State private var showPaywall = false
    @State private var editName = false
    @State private var draftName = ""
    @AppStorage("appLanguage") private var language = AppLanguage.system
    @AppStorage("hasSeenTour") private var hasSeenTour = false
    @State private var showTour = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let error = viewModel.bankError {
                    ContentUnavailableView("Unable to load questions", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    switch tab {
                    case .home: dashboard
                    case .exam: PracticeExamView(path: $path, onBack: { tab = .home })
                    case .saved: saved
                    case .profile: profile
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .practiceExam: PracticeExamView(path: $path, onBack: { path.removeLast() })
                case .parts: partsScreen
                case .flashChallenge: FlashChallengeView(path: $path)
                case .topicMastery: TopicMasteryView(path: $path)
                case .quiz(let key): QuizHost(key: key, path: $path)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { if path.isEmpty { bottomNav } }
        }
        .tint(.brand).background(Color.bg)
        .preferredColorScheme(.light)
        .onChange(of: path) { old, new in
            if !old.isEmpty && new.isEmpty { tab = .home }
        }
        .sheet(isPresented: $showPaywall) { GoProView() }
        .fullScreenCover(isPresented: $showTour) {
            ProductTourView { showTour = false; hasSeenTour = true }
                .environment(\.locale, language.locale ?? Locale.autoupdatingCurrent)
        }
        .task { if !hasSeenTour { showTour = true } }
        .alert("Your name", isPresented: $editName) {
            TextField("Name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.updateLearnerName(draftName)
            }
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                VStack(alignment: .leading, spacing: 0) {
                    continueCard
                    HStack {
                        Text("Study modes").font(.h(16))
                        Spacer()
                        Button("See all") { path.append(.parts) }.font(.system(size: 12.5, weight: .medium)).frame(minHeight: 44)
                    }.padding(.top, 10)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        modeCard("checkmark.square", "Practice Exam", .white, .navy,
                                 "\(min(viewModel.study.examCount, viewModel.study.examQuestions.count)) questions · \(viewModel.study.examMinutes) min", .practiceExam)
                        modeCard("arrow.counterclockwise", "Missed Questions", .red, Color(0xFFF1F1),
                                 "Review \(viewModel.study.missed.count) you skipped", .quiz("missed"))
                        modeCard("exclamationmark.triangle", "Incorrect", .amber, Color(0xFFF6E8),
                                 "Fix \(viewModel.study.wrong.count) wrong answers", .quiz("wrong"))
                        modeCard("bookmark", "Bookmarks", .green, Color(0xEAF7F1),
                                 "\(viewModel.study.bookmarks.count) saved questions", .quiz("bookmarks"))
                    }
                    Text("Quick practice").font(.h(16)).padding(.top, 22)
                    VStack(spacing: 12) {
                        practiceRow("bolt.fill", "Flash Challenge", "Quick packs of 10, 20 or 30 questions", .amber, .flashChallenge)
                        practiceRow("timer", "Time Trial", "Beat the clock — \(viewModel.study.timeTrialCount) questions", .red, .quiz("timetrial"))
                        practiceRow("scope", "Topic Mastery", "Focus on the parts you choose", .brand, .topicMastery)
                    }.padding(.top, 12)
                    if viewModel.study.bank.isDemo {
                        Label("Demo data · 2 illustrative questions, not an official exam bank.", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(Color.slate).padding(.top, 16)
                    }
                    if let error = viewModel.persistenceError { Text(error).font(.caption).foregroundStyle(Color.red).padding(.top, 12) }
                }.padding(.horizontal, 22).padding(.top, 20).padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.bg)
            }
        }
        .background(alignment: .top) {
            LinearGradient(colors: [.navy, .navy2], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 340).ignoresSafeArea(edges: .top)
        }
        .background(Color.bg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting).font(.system(size: 13)).foregroundStyle(Color(0x93A9C0))
                    Text(viewModel.study.learnerName).font(.h(22, .bold)).foregroundStyle(.white)
                }
                Spacer()
                Button { tab = .profile } label: {
                    Text(initials).font(.h(16)).foregroundStyle(Color(0xC7D8EA)).frame(width: 44, height: 44)
                        .background(Color(0x23405C), in: .rect(cornerRadius: 14))
                }.accessibilityLabel("Open profile")
            }
            HStack(spacing: 18) {
                ProgressRing(value: viewModel.study.readiness, size: 76, lineWidth: 8, track: Color(0x2C4964), tint: Color(0x4C6FEF)) {
                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.study.readiness * 100))%").font(.h(20, .bold)).foregroundStyle(.white)
                        Text("mastered").font(.system(size: 10)).foregroundStyle(Color(0xA9BED3))
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Study progress").font(.system(size: 13)).foregroundStyle(Color(0xA9BED3))
                        Text(viewModel.study.readiness >= 1 ? "Great work — try another practice round" : "Keep it up — every question counts")
                            .font(.h(15)).foregroundStyle(.white)
                    }
                    HStack(spacing: 6) { pill("\(viewModel.study.answered.count) answered"); pill("\(viewModel.study.bookmarks.count) saved") }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18).background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.10)))
        }
        .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 26)
        .background {
            LinearGradient(colors: [.navy, .navy2], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea(edges: .top)
        }
    }

    private var continueCard: some View {
        let draft = viewModel.study.latestDraft
        let first = viewModel.study.bank.parts.first { !$0.isPremium && !$0.questions.isEmpty }
        return Button {
            if let draft { path.append(.quiz(draft.key)) }
            else if let first { path.append(.quiz(first.id)) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "play").font(.system(size: 20, weight: .medium)).foregroundStyle(Color.brand)
                    .frame(width: 46, height: 46).background(Color.brandSoft, in: .rect(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    if let draft {
                        Text("Continue: \(draft.title)").font(.h(15))
                        Text("Question \(draft.index + 1) of \(draft.questionIDs.count)")
                            .font(.system(size: 12.5)).foregroundStyle(Color.slate)
                    } else {
                        Text("Start: \(first?.name ?? "Practice")").font(.h(15))
                        Text("\(first?.questions.count ?? 0) questions · learn at your pace")
                            .font(.system(size: 12.5)).foregroundStyle(Color.slate)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Color.slate)
            }.foregroundStyle(Color.navy).card()
        }.buttonStyle(.plain).disabled(draft == nil && first == nil)
    }

    private var partsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Button { path.removeLast() } label: {
                    Label("Home", systemImage: "chevron.left").font(.system(size: 14, weight: .semibold)).frame(minHeight: 44)
                }
                Text("Question bank").font(.h(28, .bold))
                Text(viewModel.study.bank.title).font(.subheadline).foregroundStyle(Color.slate)
                    .padding(.bottom, 6)
                ForEach(Array(viewModel.study.bank.parts.enumerated()), id: \.element.id) { index, part in
                    let locked = part.isPremium && !viewModel.study.isPremium
                    Button {
                        if locked { showPaywall = true }
                        else { path.append(.quiz(part.id)) }
                    } label: {
                        HStack(spacing: 14) {
                            IconChip(systemName: locked ? "lock.fill" : "doc.text.fill",
                                     tint: part.isPremium ? .amber : .brand)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(part.name).font(.h(15.5))
                                Text("\(part.questions.count) questions").font(.caption).foregroundStyle(Color.slate)
                            }
                            Spacer()
                            if locked {
                                Text("PRO").font(.system(size: 10.5, weight: .bold)).foregroundStyle(Color.amber)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.amber.opacity(0.14), in: .capsule)
                            }
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.slate)
                        }.foregroundStyle(Color.navy).card()
                    }.buttonStyle(.plain)
                }
            }.padding(22)
        }.background(Color.bg)
        .navigationBarBackButtonHidden().toolbar(.hidden, for: .navigationBar)
    }

    private var saved: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Saved questions").font(.h(26, .bold))
                if viewModel.study.questions(with: viewModel.study.bookmarks).isEmpty {
                    ContentUnavailableView("Your collection starts here", systemImage: "bookmark",
                                           description: Text("Tap Save during a quiz to revisit a question."))
                } else {
                    PrimaryButton(title: "Practice saved questions") { path.append(.quiz("bookmarks")) }
                    ForEach(viewModel.study.questions(with: viewModel.study.bookmarks)) { question in
                        HStack(alignment: .top, spacing: 12) {
                            RichText(html: question.question)
                            Button { viewModel.toggleBookmark(question) } label: {
                                Image(systemName: "bookmark.fill").frame(width: 44, height: 44)
                            }.accessibilityLabel("Remove bookmark")
                        }.card()
                    }
                }
            }.padding(22)
        }.background(Color.bg)
    }

    private var profile: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your profile").font(.h(26, .bold))
                Button { draftName = viewModel.study.learnerName; editName = true } label: {
                    HStack {
                        Text(initials).font(.h(24)).frame(width: 64, height: 64).background(Color.brandSoft, in: .rect(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewModel.study.learnerName).font(.h(18))
                            Text("Edit your name").font(.caption).foregroundStyle(Color.slate)
                        }
                        Spacer()
                        Image(systemName: "pencil")
                    }.foregroundStyle(Color.navy).card()
                }.buttonStyle(.plain)
                VStack(spacing: 16) {
                    LabeledContent("Questions studied", value: "\(viewModel.study.answered.count)")
                    LabeledContent("Completed attempts", value: "\(viewModel.study.completedAttempts)")
                    LabeledContent("Best practice score", value: "\(Int(viewModel.study.bestScore * 100))%")
                    LabeledContent("Saved questions", value: "\(viewModel.study.bookmarks.count)")
                }.font(.subheadline).card()
                HStack(spacing: 12) {
                    IconChip(systemName: "globe", tint: .brand, size: 40)
                    Text("Language").font(.h(15))
                    Spacer()
                    Picker("Language", selection: $language) {
                        ForEach(AppLanguage.allCases) { lang in
                            (lang == .system ? Text("Match device") : Text(verbatim: lang.nativeName)).tag(lang)
                        }
                    }.labelsHidden().tint(Color.slate)
                }.foregroundStyle(Color.navy).card()
                Button { showTour = true } label: {
                    HStack(spacing: 12) {
                        IconChip(systemName: "map", tint: .brand, size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Product tour").font(.h(15))
                            Text("Replay the walkthrough").font(.caption).foregroundStyle(Color.slate)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }.foregroundStyle(Color.navy).card()
                }.buttonStyle(.plain)
                Button { showPaywall = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill").foregroundStyle(Color.amber)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unlock the full question bank").font(.h(15))
                            Text("Explore Premium").font(.caption).foregroundStyle(Color.slate)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }.foregroundStyle(Color.navy).card()
                }.buttonStyle(.plain)
                Text(viewModel.study.bank.updatedTime).font(.caption).foregroundStyle(Color.slate)
                Text("Offline practice. Progress stays on this device.\nIndependent study app, not affiliated with Scrum.org.")
                    .font(.caption).foregroundStyle(Color.slate)
            }.padding(22)
        }.background(Color.bg)
    }

    private var bottomNav: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { item in
                Button { tab = item } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon).font(.system(size: 21, weight: tab == item ? .semibold : .regular))
                        Text(item.title).font(.system(size: 10.5, weight: tab == item ? .semibold : .regular))
                    }.foregroundStyle(tab == item ? Color.brand : Color.slate)
                        .frame(maxWidth: .infinity, minHeight: 52).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityElement(children: .ignore).accessibilityLabel(item.title)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }.padding(.horizontal, 14).padding(.top, 6).background(.white).overlay(alignment: .top) { Divider() }
    }

    private var initials: String { viewModel.study.learnerName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased() }
    private var greeting: LocalizedStringKey {
        switch Calendar.current.component(.hour, from: .now) {
        case ..<12: "Good morning"
        case ..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private func pill(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.system(size: 11)).foregroundStyle(Color(0xBFD0E1))
            .padding(.horizontal, 9).padding(.vertical, 4).background(Color(0x23405C), in: .rect(cornerRadius: 7))
    }

    private func practiceRow(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey, _ tint: Color, _ route: Route) -> some View {
        Button { path.append(route) } label: {
            HStack(spacing: 14) {
                IconChip(systemName: icon, tint: tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.h(15.5))
                    Text(subtitle).font(.caption).foregroundStyle(Color.slate)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.slate)
            }.foregroundStyle(Color.navy).card()
        }.buttonStyle(.plain)
    }

    private func modeCard(_ icon: String, _ title: LocalizedStringKey, _ tint: Color, _ background: Color, _ subtitle: LocalizedStringKey, _ route: Route) -> some View {
        Button { path.append(route) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon).font(.system(size: 19, weight: .medium)).foregroundStyle(tint)
                    .frame(width: 40, height: 40).background(background, in: .rect(cornerRadius: 11))
                Text(title).font(.h(14.5)).padding(.top, 12)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Color.slate).padding(.top, 3)
            }.frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading).foregroundStyle(Color.navy).card(15, radius: 16)
        }.buttonStyle(.plain)
    }
}

struct ProgressRing<Label: View>: View {
    let value: Double
    var size: CGFloat = 76
    var lineWidth: CGFloat = 8
    var track: Color = Color(0xE4EAF1)
    var tint: Color = .brand
    @ViewBuilder var label: Label

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle().trim(from: 0, to: max(0, min(1, value)))
                .stroke(tint, style: .init(lineWidth: lineWidth, lineCap: .round)).rotationEffect(.degrees(-90))
            label
        }.padding(lineWidth / 2).frame(width: size, height: size)
    }
}
