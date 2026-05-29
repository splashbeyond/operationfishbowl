import SwiftUI

@main
struct TimeTankApp: App {
    @State private var model = TimeTankModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.light)
        }
    }
}
