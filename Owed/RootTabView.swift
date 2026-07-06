import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            OwedHomeView()
                .tabItem {
                    Label("Loans", systemImage: "person.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(OWTheme.plum)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(OWTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(OwedStore())
        .environmentObject(PurchaseManager())
}
