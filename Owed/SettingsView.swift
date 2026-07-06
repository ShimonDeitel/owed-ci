import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: OwedStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("owed_haptics_enabled") private var hapticsEnabled: Bool = true
    @State private var activeSheet: OwedSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .accessibilityIdentifier("hapticsToggle")
                }

                Section("Stats") {
                    HStack {
                        Text("Tracked Loans")
                        Spacer()
                        Text("\(store.loans.count)")
                            .foregroundStyle(OWTheme.inkFaded)
                    }
                    HStack {
                        Text("Handshake Score")
                        Spacer()
                        Text("\(Int(store.handshake.score))")
                            .foregroundStyle(OWTheme.inkFaded)
                    }
                    HStack {
                        Text("Outstanding Total")
                        Spacer()
                        Text("$\(String(format: "%.2f", store.handshake.totalOutstanding))")
                            .foregroundStyle(OWTheme.inkFaded)
                    }
                }

                Section("Owed Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(OWTheme.plum)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(OWTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/owed-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(OWTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all loans?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(OwedStore())
        .environmentObject(PurchaseManager())
}
