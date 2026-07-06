import Foundation
import Combine

@MainActor
final class OwedStore: ObservableObject {
    @Published private(set) var loans: [Loan] = []

    static let freeLoanLimit = 3

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("owed_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if loans.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        loans = [
            Loan(friendName: "Alex", amount: 40, note: "Concert tickets", dateLent: weekAgo),
            Loan(friendName: "Jamie", amount: 15, note: "Lunch", dateLent: now, isPaidBack: true, datePaidBack: now)
        ]
        save()
    }

    func canAddLoan(isPro: Bool) -> Bool {
        isPro || loans.count < Self.freeLoanLimit
    }

    @discardableResult
    func addLoan(friendName: String, amount: Double, note: String, isPro: Bool) -> Bool {
        let trimmed = friendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0, canAddLoan(isPro: isPro) else { return false }
        loans.append(Loan(friendName: trimmed, amount: amount, note: note))
        save()
        return true
    }

    func deleteLoan(_ id: UUID) {
        loans.removeAll { $0.id == id }
        save()
    }

    func markPaidBack(_ id: UUID) {
        guard let idx = loans.firstIndex(where: { $0.id == id }) else { return }
        loans[idx].isPaidBack = true
        loans[idx].datePaidBack = Date()
        save()
    }

    func markUnpaid(_ id: UUID) {
        guard let idx = loans.firstIndex(where: { $0.id == id }) else { return }
        loans[idx].isPaidBack = false
        loans[idx].datePaidBack = nil
        save()
    }

    func deleteAllData() {
        loans = []
        seedDefaults()
    }

    var handshake: HandshakeResult {
        HandshakeCalculator.compute(loans: loans)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([Loan].self, from: data) {
            loans = decoded
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(loans) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
