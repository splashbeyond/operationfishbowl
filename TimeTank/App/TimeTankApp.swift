import CoreFoundation
import ManagedSettings
import SwiftUI
import UserNotifications

@main
struct TimeTankApp: App {
    @State private var model = TimeTankModel()
    @State private var selectedTab: TimeTankTab = .tank
    @Environment(\.scenePhase) private var scenePhase

    @UIApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            RootView(selectedTab: $selectedTab)
                .environment(model)
                .preferredColorScheme(model.appearanceMode.preferredColorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .openTankTab)) { _ in
                    selectedTab = .tank
                    model.refresh()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.refresh()
            }
        }
        .onAppear {
            registerDarwinBudgetObserver()
        }
    }
}

extension Notification.Name {
    static let openTankTab = Notification.Name("openTankTab")
}

// Darwin (cross-process) notification name — posted by monitor extension when threshold fires
private let kBudgetReachedDarwinName = "com.piperstudio.timetank.budgetReached" as CFString

extension TimeTankApp {
    // Registers a Darwin observer so the main app can re-apply the shield if it's open
    // when the monitor extension fires (handles cases where ManagedSettings write from
    // the extension context fails or is delayed)
    func registerDarwinBudgetObserver() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    let store = TimeTankStore()
                    store.recordDiagnostic("Darwin budget signal received — refreshing shield.", source: "App")
                    if store.hasSelection {
                        ScreenTimeShielding.applyShield(for: store.selection)
                    }
                }
            },
            kBudgetReachedDarwinName,
            nil,
            .deliverImmediately
        )
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "bypass-expiry" {
            NotificationCenter.default.post(name: .openTankTab, object: nil)
        }
        completionHandler()
    }
}
