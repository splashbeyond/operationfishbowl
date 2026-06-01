import StoreKit
import SwiftUI
import UIKit

private struct OnboardingOption: Identifiable {
    let id: String
    let emoji: String
    let title: String
}

private enum OnboardingHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct OnboardingView: View {
    @Environment(TimeTankModel.self) private var model

    @State private var step = 0
    @State private var isGoingForward = true

    @State private var demoMurkiness: Double = 0
    @State private var lastDemoThreshold = 0
    @State private var screenTimeHours: Double = 2
    @State private var lastScreenTimeTick = 4

    @State private var selectedGoal: String?
    @State private var selectedPain: String?
    @State private var selectedTimeOfDay: String?

    @State private var showWelcomeButton = false
    @State private var welcomeScale: CGFloat = 0.9
    @State private var analysisProgress: Double = 0
    @State private var dotsRevealed = 0
    @State private var goodNewsScale: CGFloat = 0.7
    @State private var starRating = 0
    @State private var showAuthError = false
    @State private var chainTapCount = 0
    @State private var chainBroken = false
    @State private var commitmentScale: CGFloat = 1
    @State private var paywallBob = false
    @State private var bypassDemoLevel: Double = 0.18
    @State private var bypassDemoCount: Int = 0

    private let paywallStep = 25

    private let goalOptions: [OnboardingOption] = [
        .init(id: "focus", emoji: "🧘", title: "Improve focus"),
        .init(id: "scrolling", emoji: "😵", title: "Reduce mindless scrolling"),
        .init(id: "sleep", emoji: "😴", title: "Sleep better"),
        .init(id: "present", emoji: "🤝", title: "Be more present"),
        .init(id: "productive", emoji: "💪", title: "Be more productive"),
        .init(id: "curious", emoji: "👀", title: "Just curious")
    ]

    private let painOptions: [OnboardingOption] = [
        .init(id: "focus", emoji: "😤", title: "Loss of focus / procrastination"),
        .init(id: "anxiety", emoji: "😰", title: "Anxiety / overstimulation"),
        .init(id: "sleep", emoji: "😴", title: "Bad sleep"),
        .init(id: "productivity", emoji: "📉", title: "Productivity drops"),
        .init(id: "drained", emoji: "🤯", title: "I feel mentally drained"),
        .init(id: "people", emoji: "❤️", title: "Less time with people I care about")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            backgroundView

            ZStack {
                screenForStep
                    .id(step)
                    .transition(pageTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if step < paywallStep {
                progressBar
            }

        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    @ViewBuilder
    private var screenForStep: some View {
        switch step {
        case 0: welcomeScreen
        case 1: meetFinnScreen
        case 2: demoSliderScreen
        case 3: notTheProblemScreen
        case 4: personalizeIntroScreen
        case 5: goalQuestionScreen
        case 6: painQuestionScreen
        case 7: screenTimeSliderScreen
        case 8: analyzingScreen
        case 9: profileRevealScreen
        case 10: oofScreen
        case 11: yearsLostScreen
        case 12: lifeDotsScreen
        case 13: goodNewsScreen
        case 14: whyItWorksScreen
        case 15: researchScreen
        case 16: reviewScreen
        case 17: connectScreenTimeScreen
        case 18: notificationsScreen
        case 19: bypassOverLimitScreen
        case 20: bypassMurkScreen
        case 21: shieldScreen
        case 22: widgetsScreen
        case 23: commitmentScreen
        case 24: beforeAfterScreen
        default: paywallScreen
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if step == paywallStep {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.15, blue: 0.20), Color(red: 0.06, green: 0.22, blue: 0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        } else {
            Color.warmWhite.ignoresSafeArea()
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isGoingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isGoingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.tideOrange.opacity(0.18))
                Capsule()
                    .fill(Color.tideOrange)
                    .frame(width: geo.size.width * (Double(min(step, paywallStep - 1)) / Double(paywallStep - 1)))
            }
            .frame(height: 4)
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.top, 52)
    }

    private func advance() {
        OnboardingHaptics.impact(.light)
        isGoingForward = true
        withAnimation(.easeInOut(duration: 0.35)) { step = min(step + 1, paywallStep) }
    }

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 120)
            Image("FinnMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(welcomeScale)

            Spacer().frame(height: 24)
            Text("Meet Finn.")
                .font(.timeTankTitle(30))
                .foregroundStyle(Color.textDark)
            Text("He lives in your tank. Your device is his world.")
                .font(.timeTankBody(17))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()
            if showWelcomeButton {
                PrimaryButton(title: "Let's go!", systemImage: "arrow.right") { advance() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { welcomeScale = 1.05 }
            try? await Task.sleep(nanoseconds: 260_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { welcomeScale = 1.0 }
            withAnimation(.easeOut(duration: 0.3)) { showWelcomeButton = true }
        }
    }

    private var meetFinnScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 86)
            FocusTankView(pollutionLevel: 0)
                .frame(width: 220, height: 220)

            Spacer().frame(height: 18)
            Text("Meet Finn's tank.")
                .font(.timeTankTitle(28))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Text("The more you go over your budget, the murkier his water gets.\n\nKeep the tank clear. Keep Finn okay.")
                .font(.timeTankBody(17))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)
                .padding(.horizontal, 34)

            Spacer()
            PrimaryButton(title: "Continue", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var demoSliderScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("See for yourself.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
            Text("Drag to watch what happens.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)

            Spacer().frame(height: 14)
            FocusTankView(pollutionLevel: demoMurkiness)
                .frame(width: 220, height: 220)

            Spacer().frame(height: 10)
            Text(sliderStateLabel)
                .font(.timeTankHeading(16))
                .foregroundStyle(sliderLabelColor)

            Spacer().frame(height: 14)
            VStack(spacing: 6) {
                Slider(value: $demoMurkiness, in: 0...1, step: 0.005)
                    .tint(sliderTint)
                    .padding(.horizontal, 28)
                    .onChange(of: demoMurkiness) { _, value in
                        let threshold = Int(value / 0.2)
                        if threshold != lastDemoThreshold {
                            lastDemoThreshold = threshold
                            OnboardingHaptics.impact(.light)
                        }
                    }
                HStack {
                    labelText("CLEAN")
                    Spacer()
                    labelText("POLLUTED")
                }
                .padding(.horizontal, 30)
            }

            Spacer().frame(height: 16)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 10) {
                    labelText("YOUR BUDGET")
                    Text(sliderExplainerText)
                        .font(.timeTankBody(15))
                        .foregroundStyle(Color.textDark)
                        .lineSpacing(4)
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.tankTeal)
                        Text("Resets to clean every night at midnight.")
                            .font(.timeTankBody(13))
                            .foregroundStyle(Color.tankTeal)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "I get it", systemImage: "checkmark") {
                OnboardingHaptics.impact(.light)
                withAnimation(.easeInOut(duration: 0.5)) { demoMurkiness = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { advance() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private var notTheProblemScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 120)
            Text("You're not addicted.")
                .font(.timeTankTitle(28))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Text("Your time is being stolen.")
                .font(.timeTankTitle(28))
                .foregroundStyle(Color.tideOrange)
                .multilineTextAlignment(.center)
                .padding(.top, 3)

            Spacer().frame(height: 28)
            VStack(spacing: 12) {
                infoCard("📲", "Apps are designed to hijack your attention")
                infoCard("🔄", "Variable reward loops keep you coming back")
                infoCard("🛡️", "TimeTank gives your time a body, so you can see it being taken")
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "Good to know", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var personalizeIntroScreen: some View {
        basicMascotScreen(
            image: "FinnMascotAlert",
            title: "Let's set up your tank.",
            body: "Your answers help Finn know what to protect.",
            buttonTitle: "Let's do it!",
            buttonIcon: "arrow.right"
        )
    }

    private var goalQuestionScreen: some View {
        quizScreen(
            title: "What's your main goal?",
            options: goalOptions,
            selection: $selectedGoal
        )
    }

    private var painQuestionScreen: some View {
        quizScreen(
            title: "How does going over budget affect you?",
            options: painOptions,
            selection: $selectedPain
        )
    }

    private var screenTimeSliderScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 100)
            Text("How long are you on your device each day?")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("You can tell the truth.")
                .font(.timeTankBody(14).italic())
                .foregroundStyle(Color.textMuted)
                .padding(.top, 6)

            Spacer().frame(height: 32)
            Text("\(formattedHours) hrs")
                .font(.timeTankMetric(52))
                .foregroundStyle(Color.tideOrange)

            Spacer().frame(height: 16)
            Slider(value: $screenTimeHours, in: 1...12, step: 0.5)
                .tint(Color.tideOrange)
                .padding(.horizontal, 28)
                .onChange(of: screenTimeHours) { _, value in
                    let tick = Int(value * 2)
                    if tick != lastScreenTimeTick {
                        lastScreenTimeTick = tick
                        OnboardingHaptics.impact(.medium)
                    }
                }
            HStack {
                Text("1h")
                Spacer()
                Text("12h+")
            }
            .font(.timeTankBody(13))
            .foregroundStyle(Color.textMuted)
            .padding(.horizontal, 32)

            Spacer().frame(height: 12)
            Text(screenTimeReaction)
                .font(.timeTankHeading(16))
                .foregroundStyle(Color.tideOrange)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
            PrimaryButton(title: "Continue", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var analyzingScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 8) {
                Text("Analyzing your habits...")
                    .font(.timeTankBody(16))
                    .foregroundStyle(Color.textMuted)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.tideOrange.opacity(0.16))
                        Capsule()
                            .fill(Color.tideOrange)
                            .frame(width: geo.size.width * analysisProgress)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 44)
            }
            .padding(.bottom, 50)
        }
        .task {
            analysisProgress = 0
            withAnimation(.easeInOut(duration: 2.5)) { analysisProgress = 1 }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            advance()
        }
    }

    private var profileRevealScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("Your attention profile is")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
            Text(tankProfile)
                .font(.timeTankTitle(28))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer().frame(height: 20)
            Image("FinnMascotWorried")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            Spacer().frame(height: 20)
            Text(profileDescription)
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)

            Spacer().frame(height: 24)
            TimeTankCard {
                VStack(spacing: 14) {
                    metricBar(title: "Tank risk", value: min(1, screenTimeHours / 8))
                    metricBar(title: "Daily vulnerability", value: vulnerabilityValue)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "Makes sense", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var oofScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("The water\nremembers.")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.tankTeal, .tideOrange, .muddyBrown], startPoint: .topLeading, endPoint: .bottomTrailing))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            Text("Every extra scroll leaves a mark in Finn's tank.")
                .font(.timeTankBody(18))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 34)
            Spacer()
            Button("Skip") { advance() }
                .font(.timeTankButton())
                .foregroundStyle(Color.textMuted)
                .buttonStyle(.plain)
                .padding(.bottom, 48)
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { OnboardingHaptics.impact(.heavy) }
    }

    private var yearsLostScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 100)
            Image("FinnMascotDistressed")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            Spacer().frame(height: 20)
            Text("You're on track to spend")
                .font(.timeTankBody(18))
                .foregroundStyle(Color.textMuted)
            Text("\(yearsLost) years")
                .font(.timeTankMetric(64))
                .foregroundStyle(Color.muddyBrown)
            Text("of your life scrolling on this device")
                .font(.timeTankBody(18))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("Projection based on your answers.")
                .font(.timeTankBody(12).italic())
                .foregroundStyle(Color.textMuted)
                .padding(.top, 16)
            Spacer()
            PrimaryButton(title: "Next", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
        .onAppear { OnboardingHaptics.impact(.heavy) }
    }

    private var lifeDotsScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("This is what you have left.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 24)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 10), count: 8), spacing: 10) {
                ForEach(0..<72, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 18, height: 18)
                        .scaleEffect(index >= 72 - dotsRevealed ? 1 : 0.86)
                        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: dotsRevealed)
                }
            }

            Spacer().frame(height: 16)
            HStack(spacing: 18) {
                legendDot(Color.textMuted.opacity(0.35), "Life remaining")
                legendDot(Color.tideOrange, "\(yearsLost) years on your device")
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "Next", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
        .task {
            dotsRevealed = 0
            for i in 1...min(72, yearsLost) {
                try? await Task.sleep(nanoseconds: 45_000_000)
                withAnimation { dotsRevealed = i }
            }
        }
    }

    private var goodNewsScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)
            Image("FinnMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .scaleEffect(goodNewsScale)
            Spacer().frame(height: 20)
            Text("The good news is...")
                .font(.timeTankBody(18))
                .foregroundStyle(Color.textMuted)
            Text("TimeTank can help you reclaim")
                .font(.timeTankHeading(22))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Text("\(yearsRecovered) years")
                .font(.timeTankMetric(64))
                .foregroundStyle(Color.tankTeal)
            Text("back.")
                .font(.timeTankHeading(22))
                .foregroundStyle(Color.textDark)
            Spacer()
            PrimaryButton(title: "Let's do this!", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
        .task {
            OnboardingHaptics.impact(.medium)
            goodNewsScale = 0.7
            withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) { goodNewsScale = 1.0 }
        }
    }

    private var whyItWorksScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 100)
            Text("Why TimeTank works.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 28)
            VStack(spacing: 12) {
                comparisonCard(icon: "xmark", text: "App blockers → Rebound behavior", positive: false)
                comparisonCard(icon: "xmark", text: "Timers → Easy to ignore", positive: false)
                comparisonCard(icon: "checkmark", text: "TimeTank → Visual feedback that rewires behavior", positive: true)
            }
            .padding(.horizontal, 20)
            Spacer()
            PrimaryButton(title: "Continue", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var researchScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)
            Text("TimeTank is built on real science.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
            Spacer().frame(height: 28)
            TimeTankCard {
                VStack(spacing: 14) {
                    studyLink(
                        university: "University of Texas at Austin",
                        finding: "A phone nearby can reduce available cognitive capacity, even when you are not using it.",
                        url: "https://news.utexas.edu/2017/06/26/the-mere-presence-of-your-smartphone-reduces-brain-power/"
                    )
                    Divider()
                    studyLink(
                        university: "University of British Columbia",
                        finding: "Blocking mobile internet improved sustained attention, mental health, and well-being.",
                        url: "https://academic.oup.com/pnasnexus/article/4/2/pgaf017/8016017"
                    )
                    Divider()
                    studyLink(
                        university: "Heidelberg University + University of Cologne",
                        finding: "A 72-hour smartphone restriction changed brain activity linked to phone craving.",
                        url: "https://www.sciencedirect.com/science/article/abs/pii/S0306460325003442"
                    )
                }
            }
            .padding(.horizontal, 20)
            Spacer().frame(height: 20)
            VStack(spacing: 6) {
                Text("Behavioral psychology.")
                Text("Designed for sustainable focus.")
                Text("No shame. No punishment.")
            }
            .font(.timeTankBody(15))
            .foregroundStyle(Color.textMuted)
            .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Continue", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var reviewScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("Enjoying TimeTank so far?")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Text("Your rating helps others find clean water.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .padding(.horizontal, 28)

            Spacer().frame(height: 24)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        starRating = star
                        OnboardingHaptics.impact(.medium)
                        requestReviewIfAppropriate()
                    } label: {
                        Image(systemName: star <= starRating ? "star.fill" : "star")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.tideOrange)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer().frame(height: 20)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("★★★★★  4.8 from early users")
                        .font(.timeTankHeading(16))
                        .foregroundStyle(Color.tideOrange)
                    Text("\"I went from 5 hours a day to under 90 minutes. The tank getting murky was all I needed to see.\"")
                        .font(.timeTankBody(15))
                        .foregroundStyle(Color.textDark)
                        .lineSpacing(4)
                    Text("- @earlyuser")
                        .font(.timeTankBody(13))
                        .foregroundStyle(Color.textMuted)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            VStack(spacing: 12) {
                PrimaryButton(title: "Continue", systemImage: "arrow.right") { advance() }
                Button("Not now") { advance() }
                    .font(.timeTankButton())
                    .foregroundStyle(Color.textMuted)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private var connectScreenTimeScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.tideOrange.opacity(0.35), radius: 12, y: 4)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer().frame(height: 28)
            Text("Connect TimeTank to Screen Time")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("Your data is completely private and never leaves your device.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)
                .padding(.horizontal, 34)
            Spacer()
            VStack(spacing: 10) {
                PrimaryButton(title: "Continue", systemImage: "person.badge.shield.checkmark") {
                    OnboardingHaptics.impact(.light)
                    Task {
                        await model.requestAuthorization()
                        if model.isAuthorized {
                            showAuthError = false
                            advance()
                        } else {
                            showAuthError = true
                        }
                    }
                }
                if showAuthError {
                    Text("Screen Time access is required for TimeTank.")
                        .font(.timeTankBody(13))
                        .foregroundStyle(Color.muddyBrown)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private var notificationsScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 76)
            Text("TimeTank can nudge you.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("Notifications tell you when the tank needs attention, even if the app is closed.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 8)
                .padding(.horizontal, 34)

            Spacer().frame(height: 24)
            notificationPreview(
                title: "Budget spent.",
                body: "Your shield is up. Finn's tank is protected."
            )
            .padding(.horizontal, 20)

            Spacer().frame(height: 16)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 12) {
                    promiseRow(symbol: "bell.badge.fill", color: .tideOrange, text: "Get a clear alert when your budget runs out")
                    promiseRow(symbol: "timer", color: .tankTeal, text: "Know when a bypass ends and protection returns")
                    promiseRow(symbol: "lock.shield.fill", color: .amber, text: "No spam. Just important tank updates")
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "Got it", systemImage: "bell.fill") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var bypassOverLimitScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)
            Image("FinnMascotDistressed")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
            Spacer().frame(height: 18)
            Text("Going past your limit\nmakes Finn sad.")
                .font(.timeTankTitle(28))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer().frame(height: 14)
            Text("Your budget is Finn's clean water. Every extra minute past it pours mud into his bowl — the more you go over, the cloudier his world gets.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)
            Spacer().frame(height: 22)
            FocusTankView(pollutionLevel: 0.48)
                .frame(width: 165, height: 165)
            Spacer().frame(height: 8)
            Text("What 48% murky looks like for Finn.")
                .font(.timeTankBody(12).italic())
                .foregroundStyle(Color.textMuted)
            Spacer()
            PrimaryButton(title: "I see it", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
        .onAppear { OnboardingHaptics.impact(.heavy) }
    }

    private var bypassMurkScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("Bypasses let you back in.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Text("But every one makes it worse. Tap to see.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 32)

            Spacer().frame(height: 8)
            ZStack(alignment: .topTrailing) {
                FocusTankView(pollutionLevel: bypassDemoLevel)
                    .frame(width: 155, height: 155)
                Image(bypassDemoFinnImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .padding(4)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
                    .overlay { Circle().stroke(Color.peachFoam, lineWidth: 1) }
                    .offset(x: 10, y: -6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: bypassDemoCount)
            }

            Spacer().frame(height: 6)
            Text(bypassDemoStatusLabel)
                .font(.timeTankHeading(15))
                .foregroundStyle(bypassDemoCount == 0 ? Color.tankTeal : Color.tideOrange)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: bypassDemoCount)

            Spacer().frame(height: 10)
            Button {
                guard bypassDemoCount < 4 else { return }
                OnboardingHaptics.impact(.heavy)
                bypassDemoCount += 1
                withAnimation(.easeInOut(duration: 0.7)) {
                    bypassDemoLevel = min(1.0, bypassDemoLevel + 0.2)
                }
            } label: {
                let exhausted = bypassDemoCount >= 4
                HStack(spacing: 10) {
                    Image(systemName: exhausted ? "exclamationmark.triangle.fill" : "lock.open.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(exhausted ? "Finn can barely breathe" : "Use bypass \(bypassDemoCount + 1)")
                        .font(.timeTankButton())
                }
                .foregroundStyle(exhausted ? Color.white : Color.tideOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(exhausted ? Color.muddyBrown : Color.tideOrange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(exhausted ? Color.clear : Color.tideOrange.opacity(0.32), lineWidth: 1.2)
                }
                .animation(.easeInOut(duration: 0.3), value: bypassDemoCount)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer().frame(height: 10)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 10) {
                    labelText("HOW LONG EACH BYPASS WINDOW LASTS")
                    bypassWindowRow(label: "1st bypass", minutes: 5, active: bypassDemoCount == 1)
                    bypassWindowRow(label: "2nd bypass", minutes: 10, active: bypassDemoCount == 2)
                    bypassWindowRow(label: "3rd bypass", minutes: 15, active: bypassDemoCount == 3)
                    bypassWindowRow(label: "4th bypass+", minutes: 30, active: bypassDemoCount >= 4)
                    Text("Shield returns automatically when the window closes.")
                        .font(.timeTankBody(12))
                        .foregroundStyle(Color.textMuted)
                        .lineSpacing(2)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "I understand", systemImage: "checkmark") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
        .onAppear {
            bypassDemoLevel = 0.18
            bypassDemoCount = 0
        }
    }

    private var shieldScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("This is what you'll see\nwhen your budget runs out.")
                .font(.timeTankTitle(25))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("The second your time is up, the shield locks your chosen apps. Finn is protecting the tank.")
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)
                .padding(.horizontal, 30)

            Spacer().frame(height: 20)
            shieldMockup

            Spacer().frame(height: 18)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 12) {
                    promiseRow(symbol: "checkmark.shield.fill", color: .tankTeal, text: "Shield shows up the second your budget is spent")
                    promiseRow(symbol: "moon.fill", color: .tideOrange, text: "Resets every night at midnight — fresh water for Finn")
                    promiseRow(symbol: "lock.open.fill", color: .muddyBrown, text: "Bypassing lets you through, but murkies the tank")
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "Got it", systemImage: "arrow.right") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var shieldMockup: some View {
        VStack(spacing: 18) {
            // App icon dimmed with clock badge — matches real iOS Screen Time block
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.black.opacity(0.38))
                    }
                Circle()
                    .fill(Color(white: 0.18))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 5, y: 5)
            }

            VStack(spacing: 5) {
                Text("Time Limit")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                Text("You've reached your limit\non TimeTank.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Text("Ask For More Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("It's OK")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.blue)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 24, y: 10)
        .padding(.horizontal, 32)
    }

    private var widgetsScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 68)
            Text("Put Finn on your Home Screen.")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
            Text("Widgets show the tank at a glance, so you do not have to open TimeTank to know how the day is going.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 8)
                .padding(.horizontal, 30)

            Spacer().frame(height: 22)
            widgetExamplePreview
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 12) {
                    setupInstructionRow(number: 1, text: "Long press your Home Screen.")
                    setupInstructionRow(number: 2, text: "Tap the + button and search TimeTank.")
                    setupInstructionRow(number: 3, text: "Choose a widget size and tap Add Widget.")
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "I'll add one", systemImage: "square.grid.2x2.fill") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var commitmentScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            Text("Ready to protect your time?")
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("Make a commitment. Finn is counting on you.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 34)

            Spacer().frame(height: 28)
            Image(chainBroken ? "FinnMascot" : "FinnMascotWorried")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(commitmentScale)
                .onTapGesture { handleCommitmentTap() }

            Spacer().frame(height: 20)
            Text(chainBroken ? "Commitment made." : "Tap Finn 5 times to commit.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textMuted)
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < chainTapCount ? Color.tideOrange : Color.tideOrange.opacity(0.18))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 12)

            Spacer()
            if chainBroken {
                PrimaryButton(title: "Let's go!", systemImage: "arrow.right") { advance() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var beforeAfterScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            HStack(spacing: 12) {
                screenTimeBarChart(
                    label: "BEFORE",
                    avgHours: screenTimeHours,
                    color: Color.tideOrange,
                    sharedMax: screenTimeHours * 1.30
                )
                screenTimeBarChart(
                    label: "WITH TIMETANK",
                    avgHours: max(0.5, screenTimeHours * 0.5),
                    color: Color.tankTeal,
                    sharedMax: screenTimeHours * 1.30
                )
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)
            Text("Use TimeTank and reclaim your time.")
                .font(.timeTankTitle(24))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 16)
            TimeTankCard {
                VStack(alignment: .leading, spacing: 12) {
                    promiseRow(symbol: "shield.fill", color: .tankTeal, text: "Blocks your apps when your budget runs out")
                    promiseRow(symbol: "arrow.clockwise", color: .tideOrange, text: "Resets every night at midnight - fresh start")
                    promiseRow(symbol: "fish", color: .amber, text: "Finn shows you exactly how your day is going")
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "I want a clean tank", systemImage: "water.waves") { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private var paywallScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 64)
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: i % 2 == 0 ? 16 : 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(paywallBob ? 0.9 : 0.35))
                        .offset(x: [-78, 72, -52, 58][i], y: [-22, -14, 62, 52][i])
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: paywallBob)
                }
                Image("FinnMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .offset(y: paywallBob ? -6 : 6)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: paywallBob)
            }

            Spacer().frame(height: 20)
            Text("Clean your tank.\nStart today.")
                .font(.timeTankTitle(30))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)
            HStack(spacing: 8) {
                paywallBadge("4.8★  Early Reviews")
                paywallBadge("Top Screen Time App")
            }

            Spacer().frame(height: 16)
            Text("Be fully present. Keep the water clean.\nFinn is watching.")
                .font(.timeTankBody(16))
                .foregroundStyle(Color.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 20)
            VStack(spacing: 10) {
                Text("REVENUECAT PAYWALL PLACEHOLDER")
                    .font(.timeTankLabel(10))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.48))
                paywallPlan(title: "Yearly", price: "$0.77 / week", subtitle: "Billed $39.99/year", highlighted: true)
                paywallPlan(title: "Weekly", price: "$4.99 / week", subtitle: "Flexible weekly access", highlighted: false)
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)
            Button {
                OnboardingHaptics.impact(.medium)
                Task {
                    if !model.isAuthorized {
                        await model.requestAuthorization()
                    }
                    if model.isAuthorized {
                        model.completeOnboarding()
                    } else {
                        showAuthError = true
                    }
                }
            } label: {
                Label("Start Protecting Finn", systemImage: "person.badge.shield.checkmark")
                    .font(.timeTankButton())
                    .foregroundStyle(Color(red: 0.03, green: 0.16, blue: 0.19))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Button("Skip for now") { model.completeOnboarding() }
                .font(.timeTankButton())
                .foregroundStyle(Color.white.opacity(0.5))
                .buttonStyle(.plain)
                .padding(.top, 12)
            Text("Cancel anytime · Restore Purchase")
                .font(.timeTankBody(11))
                .foregroundStyle(Color.white.opacity(0.4))
                .padding(.top, 8)
            Spacer().frame(height: 40)
        }
        .task { paywallBob = true }
    }

    private func basicMascotScreen(image: String, title: String, body: String, buttonTitle: String, buttonIcon: String) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            Spacer().frame(height: 20)
            Text(title)
                .font(.timeTankTitle(28))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.center)
            Text(body)
                .font(.timeTankBody(17))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)
                .padding(.horizontal, 34)
            Spacer()
            PrimaryButton(title: buttonTitle, systemImage: buttonIcon) { advance() }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
    }

    private func quizScreen(title: String, options: [OnboardingOption], selection: Binding<String?>) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)
            Text(title)
                .font(.timeTankTitle(26))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            Spacer().frame(height: 28)
            VStack(spacing: 10) {
                ForEach(options) { option in
                    optionPill(option, selection: selection)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            DisabledPrimaryButton(title: "Continue", systemImage: "arrow.right", isEnabled: selection.wrappedValue != nil) {
                advance()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private func optionPill(_ option: OnboardingOption, selection: Binding<String?>) -> some View {
        let selected = selection.wrappedValue == option.id
        return Button {
            selection.wrappedValue = option.id
            if step == 6 {
                selectedTimeOfDay = inferTimeOfDay(from: option.id)
            }
            OnboardingHaptics.impact(.light)
        } label: {
            HStack(spacing: 12) {
                Text(option.emoji)
                    .font(.system(size: 20))
                    .frame(width: 28)
                Text(option.title)
                    .font(.timeTankBody(16))
                    .foregroundStyle(Color.textDark)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                Spacer()
            }
            .frame(height: 56)
            .padding(.horizontal, 16)
            .background(selected ? Color.tideOrange.opacity(0.12) : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.tideOrange : Color.peachFoam, lineWidth: selected ? 1.5 : 1)
            }
            .scaleEffect(selected ? 1.02 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: selected)
        }
        .buttonStyle(.plain)
    }

    private func infoCard(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 22))
            Text(text)
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textDark)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.peachFoam, lineWidth: 1)
        }
    }

    private func comparisonCard(icon: String, text: String, positive: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(positive ? Color.tankTeal : Color.coral)
                .frame(width: 24, height: 24)
                .background((positive ? Color.tankTeal : Color.coral).opacity(0.12))
                .clipShape(Circle())
            Text(text)
                .font(.timeTankBody(16))
                .foregroundStyle(Color.textDark)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer()
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .background(positive ? Color.tankTeal.opacity(0.12) : Color.coral.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(positive ? Color.tankTeal : Color.coral.opacity(0.25), lineWidth: positive ? 1.5 : 1)
        }
    }

    private func metricBar(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.timeTankLabel(10))
                    .tracking(1.2)
                    .foregroundStyle(Color.textMuted)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.timeTankLabel(10))
                    .tracking(1.0)
                    .foregroundStyle(Color.tideOrange)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.tideOrange.opacity(0.14))
                    Capsule()
                        .fill(Color.tideOrange)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 8)
        }
    }

    private func studyLink(university: String, finding: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tideOrange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(university)
                        .font(.timeTankHeading(14))
                        .foregroundStyle(Color.textDark)
                        .multilineTextAlignment(.leading)
                    Text(finding)
                        .font(.timeTankBody(13))
                        .foregroundStyle(Color.textMuted)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.textMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text)
                .font(.timeTankBody(12))
                .foregroundStyle(Color.textMuted)
                .lineLimit(2)
        }
    }

    private func screenTimeBarChart(label: String, avgHours: Double, color: Color, sharedMax: Double? = nil) -> some View {
        // Natural day-of-week variation: Sun high, Mon-Thu lower, Fri-Sat high
        let multipliers: [Double] = [1.18, 0.78, 0.85, 0.74, 0.91, 1.20, 1.30]
        let barValues = multipliers.map { avgHours * $0 }
        let peak = max(0.01, sharedMax ?? barValues.max() ?? 1.0)
        let chartH: CGFloat = 76
        let days = ["S", "M", "T", "W", "T", "F", "S"]

        let avgLabel: String = {
            if avgHours < 1 { return "\(Int((avgHours * 60).rounded()))m" }
            let h = Int(avgHours)
            let m = Int((avgHours - Double(h)) * 60)
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }()

        return VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.timeTankLabel(10))
                .tracking(1.1)
                .foregroundStyle(color)

            Text(avgLabel)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.top, 4)
                .padding(.bottom, 10)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    let ratio = CGFloat(barValues[i] / peak)
                    let isToday = i == 6
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color.opacity(0.10))
                            .frame(height: chartH)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isToday ? color : color.opacity(0.48))
                            .frame(height: max(4, chartH * ratio))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: chartH)

            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    Text(days[i])
                        .font(.system(size: 9, weight: i == 6 ? .bold : .regular))
                        .foregroundStyle(i == 6 ? color : Color.textMuted.opacity(0.65))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 5)

            Text("Daily avg")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textMuted)
                .padding(.top, 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        }
    }

    private func promiseRow(symbol: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textDark)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func notificationPreview(title: String, body: String) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("TimeTank")
                        .font(.timeTankHeading(13))
                        .foregroundStyle(Color.textDark)
                    Spacer()
                    Text("now")
                        .font(.timeTankBody(12))
                        .foregroundStyle(Color.textMuted)
                }
                Text(title)
                    .font(.timeTankHeading(15))
                    .foregroundStyle(Color.textDark)
                Text(body)
                    .font(.timeTankBody(13))
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.peachFoam, lineWidth: 1)
        }
        .shadow(color: Color.textDark.opacity(0.08), radius: 14, y: 8)
    }

    private func bypassScheduleRow(time: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(time)
                .font(.timeTankHeading(14))
                .foregroundStyle(Color.tideOrange)
                .frame(width: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.timeTankHeading(15))
                    .foregroundStyle(Color.textDark)
                Text(detail)
                    .font(.timeTankBody(13))
                    .foregroundStyle(Color.textMuted)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
    }

    private func setupInstructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.timeTankHeading(13))
                .foregroundStyle(Color.white)
                .frame(width: 26, height: 26)
                .background(Color.tideOrange)
                .clipShape(Circle())
            Text(text)
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textDark)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var widgetExamplePreview: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image("FinnMascotAlert")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 64)
                Text("28%")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("MURKY")
                    .font(.timeTankLabel(9))
                    .tracking(0.9)
                    .foregroundStyle(Color.amber)
            }
            .frame(width: 118, height: 118)
            .background(widgetPreviewBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                labelText("EXAMPLE WIDGET")
                    .foregroundStyle(Color.tankTeal)
                Text("Finn updates with your current tank pollution.")
                    .font(.timeTankHeading(17))
                    .foregroundStyle(Color.textDark)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Small shows the percentage. Larger sizes give Finn more room.")
                    .font(.timeTankBody(13))
                    .foregroundStyle(Color.textMuted)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.peachFoam, lineWidth: 1)
        }
    }

    private var widgetPreviewBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.07, blue: 0.08),
                Color(red: 0.04, green: 0.15, blue: 0.17),
                Color.tideOrange.opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func paywallBadge(_ text: String) -> some View {
        Text(text)
            .font(.timeTankLabel(10))
            .tracking(0.8)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.10))
            .clipShape(Capsule())
    }

    private func paywallPlan(title: String, price: String, subtitle: String, highlighted: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.timeTankHeading(16))
                    .foregroundStyle(Color.white)
                Text(subtitle)
                    .font(.timeTankBody(12))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            Spacer()
            Text(price)
                .font(.timeTankHeading(15))
                .foregroundStyle(highlighted ? Color.tideOrange : Color.white.opacity(0.7))
        }
        .padding(14)
        .background(Color.white.opacity(highlighted ? 0.14 : 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(highlighted ? Color.white.opacity(0.8) : Color.white.opacity(0.10), lineWidth: highlighted ? 1.2 : 1)
        }
    }

    private func labelText(_ text: String) -> Text {
        Text(text)
            .font(.timeTankLabel(10))
            .tracking(1.1)
            .foregroundStyle(Color.textMuted)
    }

    private var bypassDemoFinnImage: String {
        switch bypassDemoCount {
        case 0, 1: return "FinnMascotWorried"
        case 2: return "FinnMascotDistressed"
        default: return "FinnMascotSuffering"
        }
    }

    private var bypassDemoStatusLabel: String {
        switch bypassDemoCount {
        case 0: return "Budget just ran out — tank at \(Int(bypassDemoLevel * 100))%"
        case 1: return "\(Int(bypassDemoLevel * 100))% murky — Finn is worried"
        case 2: return "\(Int(bypassDemoLevel * 100))% murky — Finn is really struggling"
        case 3: return "\(Int(bypassDemoLevel * 100))% murky — Finn needs help"
        default: return "\(Int(bypassDemoLevel * 100))% murky — Finn can barely breathe"
        }
    }

    private func bypassWindowRow(label: String, minutes: Int, active: Bool) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(active ? Color.tideOrange : Color.tideOrange.opacity(0.14))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.timeTankBody(14))
                .foregroundStyle(active ? Color.textDark : Color.textMuted)
            Spacer()
            Text("\(minutes) min")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(active ? Color.tideOrange : Color.textMuted)
            if active {
                Text("← now")
                    .font(.timeTankLabel(9))
                    .tracking(0.8)
                    .foregroundStyle(Color.tideOrange)
            }
        }
        .padding(.vertical, 3)
        .animation(.easeInOut(duration: 0.25), value: active)
    }

    private func dotColor(for index: Int) -> Color {
        index >= 72 - dotsRevealed ? Color.tideOrange : Color.textMuted.opacity(0.35)
    }

    private func handleCommitmentTap() {
        guard chainTapCount < 5 else { return }
        OnboardingHaptics.impact(.medium)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            chainTapCount += 1
            commitmentScale = 1.12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) { commitmentScale = 1 }
        }
        if chainTapCount == 5 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) { chainBroken = true }
            OnboardingHaptics.success()
        }
    }

    private func requestReviewIfAppropriate() {
        guard starRating >= 4 else { return }
        #if !targetEnvironment(simulator)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        #endif
    }

    private func inferTimeOfDay(from pain: String) -> String {
        switch pain {
        case "sleep": return "evening"
        case "productivity", "focus": return "day"
        case "anxiety", "drained": return "all-day"
        default: return "unsure"
        }
    }

    private var sliderStateLabel: String {
        let pct = Int(demoMurkiness * 100)
        switch demoMurkiness {
        case 0..<0.01: return "Crystal clean"
        case 0..<0.20: return "\(pct)% - Finn is happy"
        case 0..<0.40: return "\(pct)% - Getting murky"
        case 0..<0.60: return "\(pct)% - Finn is worried"
        case 0..<0.80: return "\(pct)% - Finn is suffering"
        default: return "\(pct)% - Finn can barely breathe"
        }
    }

    private var sliderLabelColor: Color {
        switch demoMurkiness {
        case 0..<0.20: return .tankTeal
        case 0..<0.40: return .amber
        case 0..<0.70: return .tideOrange
        default: return .muddyBrown
        }
    }

    private var sliderTint: Color {
        switch demoMurkiness {
        case 0..<0.40: return .tankTeal
        case 0..<0.70: return .tideOrange
        default: return .muddyBrown
        }
    }

    private var sliderExplainerText: String {
        switch demoMurkiness {
        case 0..<0.01:
            return "Set a budget, like 30 minutes. Stay under it today and the water stays clean."
        case 0..<0.20:
            return "You went a little over your limit. Finn notices, but the water is still mostly clear."
        case 0..<0.40:
            return "You bypassed the block once. Each bypass adds more pollution to the tank."
        case 0..<0.60:
            return "The tank is clouding fast. You are well past your budget and Finn is getting worried."
        case 0..<0.80:
            return "Finn is struggling. Your screen time today is way over what you set."
        default:
            return "Full pollution. This is what a day completely lost to your device looks like for Finn."
        }
    }

    private var formattedHours: String {
        screenTimeHours.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(screenTimeHours))"
        : String(format: "%.1f", screenTimeHours)
    }

    private var screenTimeReaction: String {
        switch screenTimeHours {
        case 1..<2: return "Good starting point."
        case 2..<4: return "The average person's range."
        case 4..<6: return "That's a significant chunk of your day."
        case 6..<8: return "That's a significant percentage of your life."
        case 8..<10: return "More than a part-time job."
        default: return "Almost your entire waking life."
        }
    }

    private var tankProfile: String {
        switch selectedTimeOfDay {
        case "morning": return "The Morning Scroller"
        case "day": return "The Daytime Drifter"
        case "evening": return "The Nighttime Scroller"
        case "all-day": return "The Always-On"
        default: return "The Habitual Scroller"
        }
    }

    private var profileDescription: String {
        switch selectedTimeOfDay {
        case "morning":
            return "Mornings are when your attention starts leaking. Your tank plan protects the first hour so the day starts clean."
        case "day":
            return "Your biggest risk is drifting during work or school hours. TimeTank makes the cost visible before the day gets away from you."
        case "evening":
            return "Evenings are your biggest attention leak. Your plan will protect downtime and help sleep feel calmer."
        case "all-day":
            return "Your device pulls at you all day. Finn gives that invisible habit a visible signal you can respond to."
        default:
            return "Your pattern is still forming, but the tank will make it obvious. Clean water means you are staying in control."
        }
    }

    private var vulnerabilityValue: Double {
        switch selectedTimeOfDay {
        case "morning": return 0.56
        case "day": return 0.72
        case "evening": return 0.86
        case "all-day": return 0.94
        default: return 0.64
        }
    }

    private var yearsLost: Int {
        max(1, Int((screenTimeHours / 16) * 70))
    }

    private var yearsRecovered: Int {
        max(1, yearsLost / 2)
    }
}

private struct DisabledPrimaryButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.timeTankButton())
                .foregroundStyle(Color.white.opacity(isEnabled ? 1 : 0.68))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isEnabled ? Color.tideOrange : Color.textMuted.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: isEnabled ? Color.tideOrange.opacity(0.3) : Color.clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
