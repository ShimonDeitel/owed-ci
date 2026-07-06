import Foundation

/// A single loan given to a friend — what was lent, to whom, and whether
/// it has been paid back.
struct Loan: Identifiable, Codable, Equatable {
    let id: UUID
    var friendName: String
    var amount: Double
    var note: String
    var dateLent: Date
    var isPaidBack: Bool
    var datePaidBack: Date?

    init(
        id: UUID = UUID(),
        friendName: String,
        amount: Double,
        note: String = "",
        dateLent: Date = Date(),
        isPaidBack: Bool = false,
        datePaidBack: Date? = nil
    ) {
        self.id = id
        self.friendName = friendName
        self.amount = amount
        self.note = note
        self.dateLent = dateLent
        self.isPaidBack = isPaidBack
        self.datePaidBack = datePaidBack
    }
}

/// Aggregate stats for the quirky "Handshake Meter" feature: a 0-100
/// trust-style score derived from the fraction of loans paid back, plus a
/// running streak of consecutive fully-repaid loans.
struct HandshakeResult {
    let score: Double
    let paidBackStreak: Int
    let totalOutstanding: Double
}

enum HandshakeCalculator {
    static func compute(loans: [Loan]) -> HandshakeResult {
        guard !loans.isEmpty else {
            return HandshakeResult(score: 100, paidBackStreak: 0, totalOutstanding: 0)
        }
        let paidCount = loans.filter(\.isPaidBack).count
        let score = (Double(paidCount) / Double(loans.count)) * 100

        // Streak: count consecutive paid-back loans from the most recently
        // lent backwards until an unpaid one is hit.
        let sortedByDate = loans.sorted { $0.dateLent > $1.dateLent }
        var streak = 0
        for loan in sortedByDate {
            if loan.isPaidBack {
                streak += 1
            } else {
                break
            }
        }

        let outstanding = loans.filter { !$0.isPaidBack }.reduce(0.0) { $0 + $1.amount }
        return HandshakeResult(score: score, paidBackStreak: streak, totalOutstanding: outstanding)
    }
}
