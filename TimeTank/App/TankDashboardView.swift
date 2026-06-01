import FamilyControls
import DeviceActivity
import ManagedSettings
import SwiftUI

struct TankDashboardView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var homeBudgetMinutes = TimeTankConstants.defaultBudgetMinutes
    @State private var setupConfirmation: String?
    @State private var budgetTrackerRefreshID = UUID()
    private let budgetTrackerTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    header

                    FocusTankView(pollutionLevel: model.pollutionLevel) {
                        guard model.isBudgetExceededToday else { return }
                        model.refresh()
                        if model.isMonitoringEnabled && model.hasSelection {
                            ScreenTimeShielding.applyShield(for: model.selection)
                        }
                    }
                    .frame(height: 360)
                    .padding(.bottom, -70)

                    pollutionDisplay

                    budgetTrackerCard

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(model.statusMessage, systemImage: "drop.fill")
                                .font(.timeTankHeading(17))
                                .foregroundStyle(Color.textDark)

                            BudgetProgressBar(progress: model.pollutionLevel)

                            Text(model.budgetBoundaryText)
                                .font(.timeTankBody(14))
                                .foregroundStyle(Color.textMuted)
                        }
                    }

                    setupCard
                    budgetCard
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationBarHidden(true)
            .familyActivityPicker(
                headerText: "Pick the apps that eat your time.",
                footerText: "TimeTank only watches the apps, categories, and sites you choose.",
                isPresented: $isPickerPresented,
                selection: $pickerSelection
            )
            .onChange(of: isPickerPresented) { _, presented in
                guard !presented else { return }
                model.saveSelection(pickerSelection)
                model.refresh()
                setupConfirmation = model.hasEffectiveSelection ? "Apps saved." : nil
            }
            .onAppear {
                syncSetupState()
                refreshBudgetTracker()
            }
            .onChange(of: model.budgetTrackingStartDate) { _, _ in
                refreshBudgetTracker()
            }
            .onReceive(budgetTrackerTimer) { _ in
                refreshBudgetTracker()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIMETANK")
                    .font(.timeTankTitle())
                    .foregroundStyle(Color.tideOrange)

                Text("Keep the water clean.")
                    .font(.timeTankBody())
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            CurrentsBadge(balance: model.currentsBalance)
        }
    }

    private var pollutionDisplay: some View {
        VStack(spacing: 4) {
            Text("\(Int(model.pollutionLevel * 100))")
                .font(.timeTankMetric(56))
                .foregroundStyle(pollutionColor)
            Text("% murky")
                .font(.timeTankBody(13))
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, -12)
    }

    private var budgetCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR BUDGET")
                    .font(.timeTankLabel())
                    .tracking(1.2)
                    .foregroundStyle(Color.textMuted)

                if !model.hasEffectiveSelection {
                    Text("Pick your apps first. Finn only watches what you choose.")
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.textMuted)
                } else {
                    HStack {
                        Label("\(model.selectedItemCount) app\(model.selectedItemCount == 1 ? "" : "s")", systemImage: "square.grid.2x2")
                        Spacer()
                        Text(TimeTankModel.durationLabel(for: model.dailyBudgetMinutes))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                    .font(.timeTankBody(14))
                    .foregroundStyle(Color.textDark)

                    Text(model.isMonitoringEnabled ? "Finn is watching the tank." : "Start TimeTank to protect your time.")
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
    }

    private var budgetTrackerCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TODAY'S BUDGET")
                        .font(.timeTankLabel())
                        .tracking(1.2)
                        .foregroundStyle(Color.textMuted)
                    Spacer()
                    Button {
                        refreshBudgetTracker()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.tideOrange)
                            .frame(width: 30, height: 30)
                            .background(Color.tideOrange.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh budget tracker")
                }

                if model.hasSelection {
                    DeviceActivityReport(budgetTrackerContext, filter: budgetTrackerFilter)
                        .id(budgetTrackerRefreshID)
                        .frame(minHeight: 124)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(TimeTankModel.durationLabel(for: model.dailyBudgetMinutes))
                            .font(.timeTankMetric(42))
                            .foregroundStyle(Color.textDark)
                        Text("Choose apps to see exactly how much time is left today.")
                            .font(.timeTankBody(14))
                            .foregroundStyle(Color.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var setupCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: model.isMonitoringEnabled ? "checkmark.shield.fill" : "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(model.isMonitoringEnabled ? Color.tankTeal : Color.tideOrange)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(setupTitle)
                            .font(.timeTankHeading(19))
                            .foregroundStyle(Color.textDark)
                        Text(setupSubtitle)
                            .font(.timeTankBody(14))
                            .foregroundStyle(Color.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                setupAppsRow

                Divider()
                    .overlay(Color.peachFoam)

                setupBudgetControl

                if let setupConfirmation {
                    Label(setupConfirmation, systemImage: "checkmark.circle.fill")
                        .font(.timeTankBody(13))
                        .foregroundStyle(Color.tankTeal)
                }

                Button {
                    handlePrimarySetupAction()
                } label: {
                    Label(primarySetupTitle, systemImage: primarySetupIcon)
                        .font(.timeTankButton())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(model.isMonitoringEnabled ? Color.tankTeal : Color.tideOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(
                            color: (model.isMonitoringEnabled ? Color.tankTeal : Color.tideOrange).opacity(0.3),
                            radius: 12,
                            y: 4
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var setupAppsRow: some View {
        HStack(spacing: 12) {
            setupStepIcon(number: 1, isComplete: model.hasEffectiveSelection)

            VStack(alignment: .leading, spacing: 3) {
                Text("Choose protected apps")
                    .font(.timeTankBody(15))
                    .foregroundStyle(Color.textDark)
                Text(appSelectionText)
                    .font(.timeTankBody(13))
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            Button {
                pickerSelection = model.selection
                isPickerPresented = true
            } label: {
                Label(model.hasEffectiveSelection ? "Edit" : "Choose", systemImage: "square.grid.2x2")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.tideOrange)
                    .frame(width: 42, height: 42)
                    .background(Color.tideOrange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var setupBudgetControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                setupStepIcon(number: 2, isComplete: model.hasBudgetBeenSet)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Set a daily budget")
                        .font(.timeTankBody(15))
                        .foregroundStyle(Color.textDark)
                    Text("How much time is fair for those apps?")
                        .font(.timeTankBody(13))
                        .foregroundStyle(Color.textMuted)
                }

                Spacer()

                Text(TimeTankModel.durationLabel(for: homeBudgetMinutes))
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.tideOrange)
                    .contentTransition(.numericText())
            }

            Slider(
                value: Binding(
                    get: { Double(homeBudgetMinutes) },
                    set: { homeBudgetMinutes = Int(($0 / 5).rounded()) * 5 }
                ),
                in: 5...Double(TimeTankConstants.maximumBudgetMinutes),
                step: 5
            )
            .tint(Color.tideOrange)
            .disabled(model.isBudgetLockedForToday)

            HStack {
                Text("5m")
                Spacer()
                Text("2h")
                Spacer()
                Text("4h")
                Spacer()
                Text("12h")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(Color.textMuted.opacity(0.55))

            if model.isBudgetLockedForToday {
                Label("Today's budget is locked in. You can still start protection.", systemImage: "lock.fill")
                    .font(.timeTankBody(12))
                    .foregroundStyle(Color.textMuted)
            }
        }
    }

    private func setupStepIcon(number: Int, isComplete: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isComplete ? Color.tankTeal : Color.tideOrange.opacity(0.14))
                .frame(width: 30, height: 30)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color.tideOrange)
            }
        }
    }

    private var setupTitle: String {
        if model.isMonitoringEnabled { return "Finn is protecting your time." }
        return "Start here."
    }

    private var setupSubtitle: String {
        if model.isMonitoringEnabled {
            return "Your tank is live. Change apps here anytime; budget changes unlock tomorrow after today's save."
        }
        return "Pick what Finn watches, set a budget, then turn on protection from this screen."
    }

    private var appSelectionText: String {
        guard model.hasEffectiveSelection else { return "No apps picked yet." }
        return "\(model.selectedItemCount) item\(model.selectedItemCount == 1 ? "" : "s") selected."
    }

    private var primarySetupTitle: String {
        if !model.hasEffectiveSelection { return "Choose Apps" }
        if !model.isAuthorized { return "Allow Screen Time" }
        if model.isMonitoringEnabled && !model.isBudgetLockedForToday { return "Save Changes" }
        if model.isMonitoringEnabled { return "Protection Is On" }
        if model.hasBudgetBeenSet || model.isBudgetLockedForToday { return "Start Protection" }
        return "Save Budget & Start"
    }

    private var primarySetupIcon: String {
        if !model.hasEffectiveSelection { return "square.grid.2x2" }
        if !model.isAuthorized { return "person.badge.shield.checkmark" }
        if model.isMonitoringEnabled && !model.isBudgetLockedForToday { return "checkmark" }
        if model.isMonitoringEnabled { return "checkmark.shield.fill" }
        return "play.fill"
    }

    private func handlePrimarySetupAction() {
        setupConfirmation = nil

        guard model.hasEffectiveSelection else {
            pickerSelection = model.selection
            isPickerPresented = true
            return
        }

        if !model.isAuthorized {
            Task {
                await model.requestAuthorization()
                model.refresh()
                setupConfirmation = model.isAuthorized ? "Screen Time allowed." : nil
            }
            return
        }

        if !model.isBudgetLockedForToday {
            model.saveBudget(minutes: homeBudgetMinutes)
            setupConfirmation = "Budget saved."
        }

        if !model.isMonitoringEnabled {
            model.startMonitoring()
            setupConfirmation = model.isMonitoringEnabled ? "Protection started." : setupConfirmation
        }

        model.refresh()
        syncSetupState()
    }

    private func syncSetupState() {
        model.refresh()
        pickerSelection = model.selection
        homeBudgetMinutes = model.dailyBudgetMinutes
    }

    private func refreshBudgetTracker() {
        model.refresh()
        budgetTrackerRefreshID = UUID()
    }

    private var budgetTrackerFilter: DeviceActivityFilter {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, duration: 24 * 60 * 60)
        let trackingStart = model.budgetTrackingStartDate.flatMap { startDate -> Date? in
            calendar.isDate(startDate, inSameDayAs: now) ? max(startDate, today.start) : nil
        } ?? today.start
        let interval = DateInterval(start: min(trackingStart, now), end: today.end)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: model.selection.applicationTokens,
            categories: model.selection.categoryTokens,
            webDomains: model.selection.webDomainTokens
        )
    }

    private var budgetTrackerContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(TimeTankConstants.budgetTrackerContextIdentifier)
    }

    private var pollutionColor: Color {
        if model.pollutionLevel >= 1 { return .muddyBrown }
        if model.pollutionLevel >= 0.8 { return .amber }
        return .tankTeal
    }
}

struct BudgetProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.peachFoam)

                Capsule()
                    .fill(fillColor)
                    .frame(width: max(6, proxy.size.width * progress))
            }
        }
        .frame(height: 6)
    }

    private var fillColor: Color {
        if progress >= 1 { return .muddyBrown }
        if progress >= 0.8 { return .amber }
        return .tankTeal
    }
}

struct CurrentsBadge: View {
    let balance: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "centsign.circle.fill")
            Text("\(balance)")
        }
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(Color.tideOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.tideOrange.opacity(0.15))
        .clipShape(Capsule())
    }
}
