import SwiftUI

enum Route: Hashable {
    case practiceExam
    case parts
    case flashChallenge
    case quiz(String)
    
    var screenName: String {
        switch self {
        case .practiceExam: "practice_exam"
        case .parts: "question_bank"
        case .flashChallenge: "flash_challenge"
        case .quiz(let key): "quiz_\(key)"
        }
    }
}

private enum MainTab: String, CaseIterable {
    case home = "Home", questionBank = "Question bank", exam = "Exam", saved = "Saved", profile = "Profile"
    var icon: String {
        switch self {
        case .home: "house"
        case .questionBank: "books.vertical"
        case .exam: "checkmark.square"
        case .saved: "bookmark"
        case .profile: "person"
        }
    }
    var title: LocalizedStringKey {
        switch self {
        case .home: "Home"
        case .questionBank: "Practice"
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
    @AppStorage("appLanguage") private var language = AppLanguage.defaultValue
    @AppStorage("hasSeenTour") private var hasSeenTour = false
    @State private var showTour = false
    @State private var showInitialProfileSetup = false
    @State private var showExamPlanEditor = false

    init() {
        let initialTab: MainTab = switch MarketingCapture.screen {
        case .practice: .questionBank
        case .exam: .exam
        case .profile: .profile
        case .paywall: .profile
        default: .home
        }
        _tab = State(initialValue: initialTab)
        _path = State(initialValue: MarketingCapture.initialRoute)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let error = viewModel.bankError {
                    ContentUnavailableView("Unable to load questions", systemImage: "exclamationmark.triangle", description: Text(error))
                        .onAppear { Track.log("bank_load_error") }
                } else {
                    switch tab {
                    case .home: dashboard
                    case .questionBank: partsScreen
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
            if let route = new.last, new.count > old.count { Track.screen(route.screenName) }
        }
        .onChange(of: tab) { _, new in
            Track.screen("tab_\(new.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))")
        }
        .sheet(isPresented: $showPaywall) { GoProView() }
        .onChange(of: showPaywall) { _, shown in if shown { Track.screen("paywall") } }
        .fullScreenCover(isPresented: $showTour, onDismiss: {
            if hasSeenTour && viewModel.study.plannedExamDate == nil { showInitialProfileSetup = true }
        }) {
            ProductTourView {
                showTour = false
                hasSeenTour = true
                Track.log("tour_finish")
            }
            .environment(\.locale, language.locale)
        }
        .fullScreenCover(isPresented: $showInitialProfileSetup) {
            ExamProfileSetupView(name: viewModel.study.learnerName,
                                 examDate: viewModel.study.plannedExamDate,
                                 isOnboarding: true) { name, date in
                viewModel.updateExamProfile(name: name, plannedExamDate: date)
                showInitialProfileSetup = false
                Track.log("exam_profile_setup", ["days_until_exam": Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0])
            }
        }
        .sheet(isPresented: $showExamPlanEditor) {
            ExamProfileSetupView(name: viewModel.study.learnerName,
                                 examDate: viewModel.study.plannedExamDate,
                                 isOnboarding: false) { name, date in
                viewModel.updateExamProfile(name: name, plannedExamDate: date)
                Track.log("exam_profile_update")
            }
        }
        .task {
            guard !MarketingCapture.isActive else { return }
            if !hasSeenTour { showTour = true; Track.log("tour_start") }
            else if viewModel.study.plannedExamDate == nil { showInitialProfileSetup = true }
        }
        .alert("Your name", isPresented: $editName) {
            TextField("Name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.updateLearnerName(draftName)
                Track.log("learner_name_update")
            }
        }
    }
    
    private var dashboard: some View {
        VStack(spacing: 0) {
            homePinnedHeader
            ScrollView {
                VStack(spacing: 0) {
                    progressSummary
                    VStack(alignment: .leading, spacing: 0) {
                        continueCard
                        HStack {
                            Text("Study modes").font(.h(16))
                            Spacer()
                            Button("See all") { tab = .questionBank }.font(.system(size: 12.5, weight: .medium)).frame(minHeight: 44)
                        }.padding(.top, 10)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                            modeCard("checkmark.square", "Practice Exam", .white, .navy,
                                     "\(min(viewModel.study.examCount, viewModel.study.examQuestions.count)) questions · \(viewModel.study.examMinutes) min", .practiceExam)
                            modeCard("arrow.counterclockwise", "Missed Questions", .red, Color(0xFFF1F1),
                                     "Review \(viewModel.study.missed.count) you skipped", .quiz("missed"))
                            modeCard("exclamationmark.triangle", "Incorrect", .amber, Color(0xFFF6E8),
                                     "Fix \(viewModel.study.wrong.count) wrong answers", .quiz("wrong"), premium: true)
                            modeCard("bookmark", "Bookmarks", .green, Color(0xEAF7F1),
                                     "\(viewModel.study.bookmarks.count) saved questions", .quiz("bookmarks"), premium: true)
                        }
                        Text("Quick practice").font(.h(16)).padding(.top, 22)
                        VStack(spacing: 12) {
                            practiceRow("bolt.fill", "Flash Challenge", "Quick packs of 10, 20 or 30 questions", .amber, .flashChallenge, premium: true)
                            practiceRow("timer", "Time Trial", "Beat the clock — \(viewModel.study.timeTrialCount) questions", .red, .quiz("timetrial"), premium: true)
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
        }
        .background(Color.bg)
    }
    
    private var homePinnedHeader: some View {
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
        .padding(.horizontal, 22).padding(.vertical, 10)
        .background {
            LinearGradient(colors: [.navy, .navy2], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) { Divider().overlay(.white.opacity(0.1)) }
        .zIndex(1)
    }
    
    private var progressSummary: some View {
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
        .padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 22)
        .background {
            LinearGradient(colors: [.navy, .navy2], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var continueCard: some View {
        let draft = viewModel.study.latestDraft
        let first = viewModel.study.bank.parts.first { !$0.isPremium && !$0.questions.isEmpty }
        return Button {
            Track.log("continue_card_tap", ["has_draft": draft != nil])
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
        VStack(spacing: 0) {
            pageHeader("Question bank", subtitle: viewModel.study.bank.title, showsBack: !path.isEmpty) { path.removeLast() }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(viewModel.study.bank.parts.enumerated()), id: \.element.id) { index, part in
                        let locked = part.isPremium && !viewModel.study.isPremium
                        Button {
                            if locked { showPaywall = true; Track.log("paywall_open", ["source": "locked_part"]) }
                            else { path.append(.quiz(part.id)) }
                        } label: {
                            HStack(spacing: 14) {
                                IconChip(systemName: locked ? "lock.fill" : "doc.text.fill",
                                         tint: locked ? .amber : .brand)
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
                            }
                            .foregroundStyle(Color.navy).card()
                        }.buttonStyle(.plain)
                    }
                }.padding(22)
            }
        }.background(Color.bg)
            .navigationBarBackButtonHidden().toolbar(.hidden, for: .navigationBar)
    }
    
    private var saved: some View {
        VStack(spacing: 0) {
            pageHeader("Saved questions")
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if viewModel.study.questions(with: viewModel.study.bookmarks).isEmpty {
                        ContentUnavailableView("Your collection starts here", systemImage: "bookmark",
                                               description: Text("Tap Save during a quiz to revisit a question."))
                    } else {
                        PrimaryButton(title: "Practice saved questions") {
                            Track.log("saved_practice_tap", ["count": viewModel.study.bookmarks.count])
                            path.append(.quiz("bookmarks"))
                        }
                        ForEach(viewModel.study.questions(with: viewModel.study.bookmarks)) { question in
                            HStack(alignment: .top, spacing: 12) {
                                RichText(html: question.question)
                                Button {
                                    viewModel.toggleBookmark(question)
                                    Track.log("bookmark_toggle", ["saved": false, "source": "saved_tab"])
                                } label: {
                                    Image(systemName: "bookmark.fill").frame(width: 44, height: 44)
                                }.accessibilityLabel("Remove bookmark")
                            }.card()
                        }
                    }
                }.padding(22)
            }
        }.background(Color.bg)
    }
    
    private var profile: some View {
        VStack(spacing: 0) {
            pageHeader("Your profile")
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                        Menu {
                            ForEach(AppLanguage.allCases) { lang in
                                Button {
                                    language = lang
                                    Track.log("language_change", ["language": lang.rawValue])
                                } label: {
                                    if language == lang { Label(lang.nativeName, systemImage: "checkmark") }
                                    else { Text(verbatim: lang.nativeName) }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(verbatim: language.nativeName).lineLimit(1).minimumScaleFactor(0.85)
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(Color.slate)
                            .frame(minWidth: 124, alignment: .trailing)
                        }
                        .accessibilityLabel("Language")
                        .accessibilityValue(language.nativeName)
                    }.foregroundStyle(Color.navy).card()
                    Button { showExamPlanEditor = true; Track.log("exam_plan_open", ["has_date": viewModel.study.plannedExamDate != nil]) } label: {
                        HStack(spacing: 12) {
                            IconChip(systemName: "calendar", tint: .brand, size: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Planned exam").font(.h(15))
                                Text(plannedExamDateText).font(.caption).foregroundStyle(Color.slate)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.foregroundStyle(Color.navy).card()
                    }.buttonStyle(.plain)
                    Button { showTour = true; Track.log("tour_start", ["source": "profile"]) } label: {
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
                    if !viewModel.study.isPremium {
                        Button { showPaywall = true; Track.log("paywall_open", ["source": "profile"]) } label: {
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
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 22)
            }
        }.background(Color.bg)
    }
    
    private func pageHeader(_ title: LocalizedStringKey, subtitle: String? = nil,
                            showsBack: Bool = false, onBack: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 12) {
            if showsBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.slate2).frame(width: 44, height: 44)
                        .background(.white, in: .rect(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.hairline))
                }.accessibilityLabel("Back")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.h(21, .bold)).foregroundStyle(Color.navy)
                if let subtitle { Text(verbatim: subtitle).font(.caption).foregroundStyle(Color.slate).lineLimit(1) }
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .pinnedHeader()
    }
    
    private var bottomNav: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { item in
                Button {
                    if item == .saved && !viewModel.study.isPremium {
                        showPaywall = true
                        Track.log("paywall_open", ["source": "saved_tab"])
                    } else {
                        tab = item
                    }
                } label: {
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
    private var plannedExamDateText: String {
        guard let date = viewModel.study.plannedExamDate else { return String(localized: "Set exam date") }
        return date.formatted(date: .long, time: .omitted)
    }
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
    
    private func practiceRow(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey, _ tint: Color,
                             _ route: Route, premium: Bool = false) -> some View {
        let locked = premium && !viewModel.study.isPremium
        return Button {
            if locked {
                showPaywall = true
                Track.log("paywall_open", ["source": "premium_mode"])
            } else {
                path.append(route)
            }
        } label: {
            HStack(spacing: 14) {
                IconChip(systemName: icon, tint: tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.h(15.5))
                    Text(subtitle).font(.caption).foregroundStyle(Color.slate)
                }
                Spacer(minLength: 0)
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(locked ? Color.amber : Color.slate)
            }.foregroundStyle(Color.navy).card()
        }.buttonStyle(.plain)
    }
    
    private func modeCard(_ icon: String, _ title: LocalizedStringKey, _ tint: Color, _ background: Color,
                          _ subtitle: LocalizedStringKey, _ route: Route, premium: Bool = false) -> some View {
        let locked = premium && !viewModel.study.isPremium
        return Button {
            if locked {
                showPaywall = true
                Track.log("paywall_open", ["source": "premium_mode"])
            } else {
                path.append(route)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: icon).font(.system(size: 19, weight: .medium)).foregroundStyle(tint)
                        .frame(width: 40, height: 40).background(background, in: .rect(cornerRadius: 11))
                    Spacer()
                    if locked {
                        Text("PRO").font(.system(size: 10.5, weight: .bold)).foregroundStyle(Color.amber)
                    }
                }
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
