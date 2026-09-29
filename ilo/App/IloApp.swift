import SwiftUI

@main
struct IloApp: App {
    @State private var model = AppModel()
    @State private var store = PurchaseService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(store)
                .tint(Palette.ink)
                .preferredColorScheme(.light)
        }
    }
}
