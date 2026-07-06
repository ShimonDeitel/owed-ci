import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ZStack {
                OWTheme.backdrop.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(OWTheme.goldBright)
                        .padding(.top, 40)

                    Text("Owed Pro")
                        .font(OWTheme.titleFont)
                        .foregroundStyle(OWTheme.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("infinity", "Track unlimited loans")
                        featureRow("clock.arrow.circlepath", "Full repayment history")
                        featureRow("sparkles", "Support future updates")
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        purchasing = true
                        Task {
                            await purchases.purchase()
                            purchasing = false
                            if purchases.isPro { dismiss() }
                        }
                    } label: {
                        HStack {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(purchases.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(OWTheme.plum)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(purchasing || purchases.product == nil)
                    .padding(.horizontal, 24)

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(OWTheme.inkFaded)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundStyle(OWTheme.ink)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(OWTheme.goldBright)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(OWTheme.ink)
        }
    }
}

#Preview {
    PaywallView().environmentObject(PurchaseManager())
}
