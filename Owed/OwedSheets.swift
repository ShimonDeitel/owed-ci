import SwiftUI

enum OwedSheet: Identifiable {
    case addLoan
    case loanDetail(Loan)
    case paywall

    var id: String {
        switch self {
        case .addLoan: return "addLoan"
        case .loanDetail(let l): return "detail-\(l.id)"
        case .paywall: return "paywall"
        }
    }
}

struct AddLoanFormView: View {
    @EnvironmentObject private var store: OwedStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var friendName: String = ""
    @State private var amountText: String = ""
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Loan") {
                    TextField("Friend's name", text: $friendName)
                        .accessibilityIdentifier("friendNameField")
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("loanAmountField")
                    TextField("Note (optional)", text: $note)
                        .accessibilityIdentifier("loanNoteField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("New Loan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let amount = Double(amountText) ?? 0
                        _ = store.addLoan(friendName: friendName, amount: amount, note: note, isPro: purchases.isPro)
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(friendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(amountText) == nil || (Double(amountText) ?? 0) <= 0)
                    .accessibilityIdentifier("saveLoanButton")
                }
            }
        }
    }
}

struct LoanDetailView: View {
    @EnvironmentObject private var store: OwedStore
    @Environment(\.dismiss) private var dismiss

    let loanId: UUID

    private var loan: Loan? {
        store.loans.first { $0.id == loanId }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let loan {
                    Section("Loan") {
                        HStack {
                            Text("Friend")
                            Spacer()
                            Text(loan.friendName)
                                .foregroundStyle(OWTheme.inkFaded)
                        }
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("$\(String(format: "%.2f", loan.amount))")
                                .foregroundStyle(OWTheme.inkFaded)
                        }
                        if !loan.note.isEmpty {
                            HStack {
                                Text("Note")
                                Spacer()
                                Text(loan.note)
                                    .foregroundStyle(OWTheme.inkFaded)
                            }
                        }
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(loan.isPaidBack ? "Paid back" : "Outstanding")
                                .foregroundStyle(loan.isPaidBack ? OWTheme.success : OWTheme.danger)
                                .accessibilityIdentifier("loanStatusLabel")
                        }
                    }

                    Section {
                        if loan.isPaidBack {
                            Button("Mark as Unpaid") {
                                store.markUnpaid(loan.id)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("markUnpaidButton")
                        } else {
                            Button("Mark as Paid Back") {
                                store.markPaidBack(loan.id)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("markPaidBackButton")
                        }
                    }

                    Section {
                        Button("Delete Loan", role: .destructive) {
                            store.deleteLoan(loan.id)
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteLoanButton")
                    }
                }
            }
            .navigationTitle(loan?.friendName ?? "Loan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}
