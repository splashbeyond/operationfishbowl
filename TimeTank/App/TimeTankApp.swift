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
    }
}

extension Notification.Name {
    static let openTankTab = Notification.Name("openTankTab")
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
