import FamilyControls
import SwiftUI

struct RootView: View {
    @Environment(TimeTankModel.self) private var model
    @Binding var selectedTab: TimeTankTab

    var body: some View {
        Group {
            if model.hasSeenOnboarding {
                mainTabs
            } else {
                OnboardingView()
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            TankDashboardView()
                .tabItem { Label("Tank", systemImage: "fish") }
                .tag(TimeTankTab.tank)

            BudgetSetupView()
                .tabItem { Label("Budget", systemImage: "clock") }
                .tag(TimeTankTab.budget)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(TimeTankTab.stats)

            CurrentsView()
                .tabItem { Label("Currents", systemImage: "centsign.circle") }
                .tag(TimeTankTab.currents)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(TimeTankTab.settings)
        }
        .tint(.tideOrange)
        .background(Color.warmWhite)
    }
}

enum TimeTankTab {
    case tank
    case budget
    case stats
    case currents
    case settings
}
