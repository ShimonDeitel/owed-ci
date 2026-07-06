import SwiftUI

struct OwedHomeView: View {
    @EnvironmentObject private var store: OwedStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: OwedSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                OWTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Owed")
                                .font(OWTheme.titleFont)
                                .foregroundStyle(OWTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddLoan(isPro: purchases.isPro) {
                                    activeSheet = .addLoan
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(OWTheme.plum)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addLoanButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        handshakeMeter

                        if store.loans.isEmpty {
                            emptyState
                        } else {
                            loansList
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addLoan:
                    AddLoanFormView()
                case .loanDetail(let loan):
                    LoanDetailView(loanId: loan.id)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    /// Quirky signature feature: a "Handshake Meter" — a warm gold dial
    /// showing what fraction of loans have come back, plus the current
    /// consecutive-repaid streak, framed like a trust score between friends.
    private var handshakeMeter: some View {
        let result = store.handshake
        return VStack(spacing: 12) {
            Text("HANDSHAKE METER")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1.0)

            Gauge(value: min(max(result.score, 0), 100), in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [OWTheme.danger, OWTheme.goldBright, OWTheme.success]))
            .scaleEffect(2.2)
            .padding(.vertical, 14)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("handshakeGauge")
            .accessibilityValue("\(Int(result.score))")

            Text("\(Int(result.score))")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            if result.paidBackStreak > 0 {
                Text("\(result.paidBackStreak) paid back in a row")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityIdentifier("paidBackStreakCallout")
            }

            if result.totalOutstanding > 0 {
                Text("$\(String(format: "%.2f", result.totalOutstanding)) still outstanding")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(OWTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }

    private var loansList: some View {
        VStack(spacing: 10) {
            ForEach(store.loans) { loan in
                LoanRow(loan: loan, onTap: { activeSheet = .loanDetail(loan) })
            }
        }
        .padding(.horizontal, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(OWTheme.inkFaded)
            Text("No loans tracked yet")
                .font(OWTheme.headlineFont)
                .foregroundStyle(OWTheme.ink)
            Text("Add a loan to keep track of who owes what.")
                .font(.subheadline)
                .foregroundStyle(OWTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

struct LoanRow: View {
    let loan: Loan
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loan.friendName)
                        .font(OWTheme.headlineFont)
                        .foregroundStyle(OWTheme.ink)
                    Text("$\(String(format: "%.2f", loan.amount))\(loan.note.isEmpty ? "" : " · \(loan.note)")")
                        .font(.caption)
                        .foregroundStyle(OWTheme.inkFaded)
                }
                Spacer()
                Text(loan.isPaidBack ? "Paid" : "Owed")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(loan.isPaidBack ? OWTheme.success : OWTheme.danger)
                    .accessibilityIdentifier("loanBadge_\(loan.friendName)")
            }
            .padding(12)
            .background(OWTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(OWTheme.rule, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OwedHomeView()
        .environmentObject(OwedStore())
        .environmentObject(PurchaseManager())
}
