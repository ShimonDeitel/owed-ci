import SwiftUI

@main
struct OwedApp: App {
    @StateObject private var store = OwedStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
