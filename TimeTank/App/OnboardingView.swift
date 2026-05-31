import SwiftUI

// MARK: - App category tiles

private struct AppCategoryItem: Identifiable {
    let id: String
    let emoji: String
    let label: String
}

private let kAppCategories: [AppCategoryItem] = [
    .init(id: "social",    emoji: "💬", label: "Social"),
    .init(id: "video",     emoji: "📱", label: "Short Video"),
    .init(id: "news",      emoji: "📰", label: "News"),
    .init(id: "games",     emoji: "🎮", label: "Games"),
    .init(id: "streaming", emoji: "🎬", label: "Streaming"),
    .init(id: "messages",  emoji: "💌", label: "Messaging"),
]

// MARK: - OnboardingView
// 6-screen Brainrot-style flow:
//   0 Hook → 1 Mirror → 2 Slider demo → 3 Categories → 4 Promise → 5 Paywall placeholder

struct OnboardingView: View {
    @Environment(TimeTankModel.self) private var model

    @State private var step = 0
    @State private var hookPollution: Double = 0
    @State private var showHookButton = false
    @State private var sliderPollution: Double = 0
    @State private var selectedCategories: Set<String> = []
    @State private var isGoingForward = true

    private let kPaywallStep = 5

    var body: some View {
        ZStack(alignment: .top) {
            Color.warmWhite.ignoresSafeArea()

            // Screen content — directional slide transition
            ZStack {
                if step == 0 { hookScreen.transition(pageTransition) }
                if step == 1 { mirrorScreen.transition(pageTransition) }
                if step == 2 { sliderScreen.transition(pageTransition) }
                if step == 3 { categoriesScreen.transition(pageTransition) }
                if step == 4 { promiseScreen.transition(pageTransition) }
                if step == 5 { paywallScreen.transition(pageTransition) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Progress dots — hidden on paywall
            if step < kPaywallStep {
                progressDots
                    .padding(.top, 54)
            }

            // Back chevron — steps 1–4 only (no back on hook or paywall)
            if step > 0 && step < kPaywallStep {
                HStack {
                    Button {
                        isGoingForward = false
                        withAnimation(.easeInOut(duration: 0.3)) { step -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.textMuted)
                            .padding(14)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.top, 46)
            }
        }
    }

    // MARK: - Transition

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isGoingForward ? .trailing : .leading).combined(with: .opacity),
            removal:   .move(edge: isGoingForward ? .leading  : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<kPaywallStep, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.tideOrange : Color.tideOrange.opacity(0.18))
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        isGoingForward = true
        withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: SCREEN 1 — Hook (animated tank getting murky)
    // ─────────────────────────────────────────────────────────────────────────

    private var hookScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)

            FocusTankView(pollutionLevel: hookPollution)
                .frame(width: 264, height: 264)

            Spacer().frame(height: 20)

            VStack(spacing: 10) {
                Text(hookHeadline)
                    .font(.timeTankTitle(28))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.45), value: hookHeadline)

                Text(hookSubtitle)
                    .font(.timeTankBody(17))
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .animation(.easeInOut(duration: 0.45), value: hookSubtitle)
            }
            .padding(.horizontal, 32)
            .frame(minHeight: 120, alignment: .top)

            Spacer()

            if showHookButton {
                PrimaryButton(title: "Show me what happens", systemImage: "arrow.right") {
                    advance()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task { await runHookAnimation() }
    }

    private var hookHeadline: String {
        if hookPollution < 0.12 { return "This is Finn." }
        if hookPollution < 0.40 { return "The water is changing." }
        if hookPollution < 0.62 { return "Your phone is doing this." }
        return "This is what it costs."
    }

    private var hookSubtitle: String {
        if hookPollution < 0.12 { return "He lives in your phone. Right now the water is clean." }
        if hookPollution < 0.40 { return "Every hour on your phone adds to the murk." }
        if hookPollution < 0.62 { return "The apps that eat your time — they're the pollution." }
        return "4 hours on your phone every day is 70 full days of your life, every year."
    }

    private func runHookAnimation() async {
        try? await Task.sleep(nanoseconds: 1_300_000_000)
        withAnimation(.easeIn(duration: 4.2)) { hookPollution = 0.72 }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        withAnimation(.easeOut(duration: 0.45)) { showHookButton = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: SCREEN 2 — Mirror (the data)
    // ─────────────────────────────────────────────────────────────────────────

    private var mirrorScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 98)

            VStack(spacing: 6) {
                Text("4 hrs 37 min")
                    .font(.timeTankMetric(50))
                    .foregroundStyle(Color.tideOrange)
                Text("on phones every day, on average.")
                    .font(.timeTankBody(18))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                mirrorRow(value: "70 days", label: "lost per year to scrolling")
                mirrorRow(value: "6.4 years", label: "of your life gone by age 80")
                mirrorRow(value: "11 pm", label: "most common time to scroll in bed")
            }
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: "That's too much", systemImage: "arrow.right") {
                    advance()
                }
                Button("I'm different") { advance() }
                    .font(.timeTankButton())
                    .foregroundStyle(Color.textMuted)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private func mirrorRow(value: String, label: String) -> some View {
        HStack(spacing: 14) {
            Text(value)
                .font(.timeTankHeading(15))
                .foregroundStyle(Color.tideOrange)
                .frame(width: 94, alignment: .leading)
            Text(label)
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textMuted)
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: SCREEN 3 — Interactive Slider Demo (the key screen)
    // ─────────────────────────────────────────────────────────────────────────

    private var sliderScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 86)

            VStack(spacing: 6) {
                Text("Here's how it works.")
                    .font(.timeTankTitle(26))
                    .foregroundStyle(Color.textDark)
                Text("Drag the slider to see Finn react.")
                    .font(.timeTankBody(16))
                    .foregroundStyle(Color.textMuted)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)

            Spacer().frame(height: 14)

            FocusTankView(pollutionLevel: sliderPollution)
                .frame(width: 206, height: 206)

            Spacer().frame(height: 8)

            // State label (animates as slider crosses thresholds)
            Text(sliderStateLabel)
                .font(.timeTankHeading(16))
                .foregroundStyle(sliderLabelColor)
                .animation(.easeInOut(duration: 0.22), value: sliderStateLabel)

            Spacer().frame(height: 14)

            // Slider + axis labels
            VStack(spacing: 6) {
                Slider(value: $sliderPollution, in: 0...1, step: 0.005)
                    .tint(sliderTint)
                    .animation(.easeInOut(duration: 0.2), value: sliderTint)
                    .padding(.horizontal, 24)

                HStack {
                    Text("CLEAN")
                        .font(.timeTankLabel())
                        .tracking(1.1)
                        .foregroundStyle(Color.textMuted)
                    Spacer()
                    Text("POLLUTED")
                        .font(.timeTankLabel())
                        .tracking(1.1)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.horizontal, 28)
            }

            Spacer().frame(height: 14)

            // Explainer card
            TimeTankCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR BUDGET")
                        .font(.timeTankLabel())
                        .tracking(1.2)
                        .foregroundStyle(Color.textMuted)

                    Text(sliderExplainerText)
                        .font(.timeTankBody(15))
                        .foregroundStyle(Color.textDark)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut(duration: 0.25), value: sliderExplainerText)

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

            PrimaryButton(title: "Got it", systemImage: "checkmark") {
                withAnimation(.easeInOut(duration: 0.5)) { sliderPollution = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { advance() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private var sliderStateLabel: String {
        let pct = Int(sliderPollution * 100)
        switch sliderPollution {
        case 0..<0.01: return "Crystal clean"
        case 0..<0.20: return "\(pct)% — Finn is happy"
        case 0..<0.40: return "\(pct)% — Getting murky"
        case 0..<0.60: return "\(pct)% — Finn is worried"
        case 0..<0.80: return "\(pct)% — Finn is suffering"
        default:       return "\(pct)% — Finn can barely breathe"
        }
    }

    private var sliderLabelColor: Color {
        switch sliderPollution {
        case 0..<0.20: return Color.tankTeal
        case 0..<0.40: return Color.amber
        case 0..<0.70: return Color.tideOrange
        default:       return Color.muddyBrown
        }
    }

    private var sliderTint: Color {
        switch sliderPollution {
        case 0..<0.40: return Color.tankTeal
        case 0..<0.70: return Color.tideOrange
        default:       return Color.muddyBrown
        }
    }

    private var sliderExplainerText: String {
        switch sliderPollution {
        case 0..<0.01:
            return "Set a budget — say 30 minutes. Stay under it today and the water stays clean."
        case 0..<0.20:
            return "You went a little over your limit. Finn notices, but the water's still mostly clear."
        case 0..<0.40:
            return "You bypassed the block once. Each bypass adds more pollution to the tank."
        case 0..<0.60:
            return "The tank is clouding fast. You're well past your budget and Finn is getting worried."
        case 0..<0.80:
            return "Finn is struggling. Your screen time today is way over what you set."
        default:
            return "Full pollution. This is what a day completely lost to your phone looks like for Finn."
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: SCREEN 4 — Categories
    // ─────────────────────────────────────────────────────────────────────────

    private var categoriesScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 98)

            VStack(spacing: 8) {
                Text("Where does your time go?")
                    .font(.timeTankTitle(26))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)
                Text("Pick the apps that pull you in.")
                    .font(.timeTankBody(17))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 28)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(kAppCategories) { cat in
                    categoryTile(cat)
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            Text("You'll pick specific apps on the next screen.")
                .font(.timeTankBody(13))
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)

            Spacer()

            PrimaryButton(
                title: selectedCategories.isEmpty ? "Skip for now" : "These are mine",
                systemImage: selectedCategories.isEmpty ? "arrow.right" : "checkmark"
            ) { advance() }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private func categoryTile(_ cat: AppCategoryItem) -> some View {
        let selected = selectedCategories.contains(cat.id)
        return Button {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                if selected { selectedCategories.remove(cat.id) }
                else        { selectedCategories.insert(cat.id) }
            }
        } label: {
            VStack(spacing: 6) {
                Text(cat.emoji)
                    .font(.system(size: 26))
                Text(cat.label)
                    .font(.timeTankLabel(11))
                    .tracking(0.5)
                    .foregroundStyle(selected ? Color.tideOrange : Color.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selected ? Color.tideOrange.opacity(0.10) : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        selected ? Color.tideOrange : Color.peachFoam,
                        lineWidth: selected ? 1.5 : 1
                    )
            }
            .scaleEffect(selected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: SCREEN 5 — The Promise (before/after)
    // ─────────────────────────────────────────────────────────────────────────

    private var promiseScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 88)

            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    FocusTankView(pollutionLevel: 0.0)
                        .frame(width: 126, height: 126)
                    Text("WITH TIMETANK")
                        .font(.timeTankLabel(10))
                        .tracking(1.1)
                        .foregroundStyle(Color.tankTeal)
                }

                VStack(spacing: 8) {
                    FocusTankView(pollutionLevel: 0.85)
                        .frame(width: 126, height: 126)
                    Text("WITHOUT IT")
                        .font(.timeTankLabel(10))
                        .tracking(1.1)
                        .foregroundStyle(Color.muddyBrown)
                }
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                Text("TimeTank gives your\nscreen time a body.")
                    .font(.timeTankTitle(24))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)

                Text("You can see the cost in real time. When the tank is clean, you're in control. When you slip, Finn shows you before it's too late.")
                    .font(.timeTankBody(16))
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 20)

            TimeTankCard {
                VStack(alignment: .leading, spacing: 12) {
                    promiseRow(icon: "shield.fill",      color: .tankTeal,    text: "Blocks your apps when your budget runs out")
                    promiseRow(icon: "arrow.clockwise",  color: .tideOrange,  text: "Resets every night at midnight — fresh start")
                    promiseRow(icon: "fish",             color: .amber,       text: "Finn reflects exactly how your day is going")
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            PrimaryButton(title: "I want a clean tank", systemImage: "water.waves") {
                advance()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    private func promiseRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textDark)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: SCREEN 6 — Paywall placeholder
    // RevenueCat drops in here. For testing: taps through to permission + completion.
    // ─────────────────────────────────────────────────────────────────────────

    private var paywallScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)

            FocusTankView(pollutionLevel: 0.0)
                .frame(width: 148, height: 148)

            Spacer().frame(height: 18)

            VStack(spacing: 8) {
                Text("Clean your tank.\nStart today.")
                    .font(.timeTankTitle(30))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)

                Text("Join thousands of people who chose clean water.")
                    .font(.timeTankBody(16))
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 24)

            // ── RevenueCat paywall goes here ──────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.tideOrange.opacity(0.55), Color.coral.opacity(0.25)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }

                VStack(spacing: 10) {
                    Text("REVENUE CAT PAYWALL")
                        .font(.timeTankLabel(10))
                        .tracking(1.4)
                        .foregroundStyle(Color.textMuted)

                    HStack(spacing: 12) {
                        planPill(label: "Weekly",  price: "$4.99/wk", badge: "Most Popular", highlighted: false)
                        planPill(label: "Yearly",  price: "$0.77/wk", badge: "Best Value",   highlighted: true)
                    }

                    Text("Billed $39.99/year · Cancel anytime")
                        .font(.timeTankBody(11))
                        .foregroundStyle(Color.textMuted)
                }
                .padding(20)
            }
            .frame(height: 148)
            .padding(.horizontal, 20)
            // ── end paywall placeholder ───────────────────────────────────

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(
                    title: model.isAuthorized ? "Set Up Finn" : "Allow Screen Time",
                    systemImage: "person.badge.shield.checkmark"
                ) {
                    if model.isAuthorized {
                        model.completeOnboarding()
                    } else {
                        Task {
                            await model.requestAuthorization()
                            if model.isAuthorized {
                                model.completeOnboarding()
                            }
                        }
                    }
                }

                Button("Skip for now") { model.completeOnboarding() }
                    .font(.timeTankButton())
                    .foregroundStyle(Color.textMuted)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)

            if let error = model.authorizationError {
                Text(error)
                    .font(.timeTankBody(13))
                    .foregroundStyle(Color.muddyBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
            }
        }
    }

    private func planPill(label: String, price: String, badge: String, highlighted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(badge)
                .font(.timeTankLabel(9))
                .tracking(0.8)
                .foregroundStyle(highlighted ? .white : Color.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(highlighted ? Color.tideOrange : Color.peachFoam)
                .clipShape(Capsule())

            Text(label)
                .font(.timeTankHeading(14))
                .foregroundStyle(Color.textDark)

            Text(price)
                .font(.timeTankBody(13))
                .foregroundStyle(highlighted ? Color.tideOrange : Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(highlighted ? Color.tideOrange.opacity(0.07) : Color.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(highlighted ? Color.tideOrange : Color.peachFoam, lineWidth: highlighted ? 1.5 : 1)
        }
    }
}
