import XCTest
@testable import Owed

final class OwedTests: XCTestCase {
    var store: OwedStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = OwedStore()
        store.deleteAllData()
        for l in store.loans { store.deleteLoan(l.id) }
    }

    @MainActor
    func testAddLoan() {
        let added = store.addLoan(friendName: "Sam", amount: 20, note: "Coffee", isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.loans.count, 1)
        XCTAssertEqual(store.loans[0].friendName, "Sam")
        XCTAssertFalse(store.loans[0].isPaidBack)
    }

    @MainActor
    func testAddLoanRejectsEmptyName() {
        let added = store.addLoan(friendName: "  ", amount: 20, note: "", isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testAddLoanRejectsNonPositiveAmount() {
        let added = store.addLoan(friendName: "Sam", amount: 0, note: "", isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksFourthLoan() {
        _ = store.addLoan(friendName: "A", amount: 10, note: "", isPro: false)
        _ = store.addLoan(friendName: "B", amount: 10, note: "", isPro: false)
        _ = store.addLoan(friendName: "C", amount: 10, note: "", isPro: false)
        XCTAssertFalse(store.canAddLoan(isPro: false))
        let fourth = store.addLoan(friendName: "D", amount: 10, note: "", isPro: false)
        XCTAssertFalse(fourth)
        XCTAssertEqual(store.loans.count, 3)
    }

    @MainActor
    func testProAllowsUnlimitedLoans() {
        _ = store.addLoan(friendName: "A", amount: 10, note: "", isPro: true)
        _ = store.addLoan(friendName: "B", amount: 10, note: "", isPro: true)
        _ = store.addLoan(friendName: "C", amount: 10, note: "", isPro: true)
        let fourth = store.addLoan(friendName: "D", amount: 10, note: "", isPro: true)
        XCTAssertTrue(fourth)
        XCTAssertEqual(store.loans.count, 4)
    }

    @MainActor
    func testMarkPaidBack() {
        _ = store.addLoan(friendName: "Sam", amount: 20, note: "", isPro: false)
        let id = store.loans[0].id
        store.markPaidBack(id)
        XCTAssertTrue(store.loans[0].isPaidBack)
        XCTAssertNotNil(store.loans[0].datePaidBack)
    }

    @MainActor
    func testMarkUnpaid() {
        _ = store.addLoan(friendName: "Sam", amount: 20, note: "", isPro: false)
        let id = store.loans[0].id
        store.markPaidBack(id)
        store.markUnpaid(id)
        XCTAssertFalse(store.loans[0].isPaidBack)
        XCTAssertNil(store.loans[0].datePaidBack)
    }

    @MainActor
    func testDeleteLoan() {
        _ = store.addLoan(friendName: "Sam", amount: 20, note: "", isPro: false)
        let id = store.loans[0].id
        store.deleteLoan(id)
        XCTAssertTrue(store.loans.isEmpty)
    }

    // MARK: - Handshake math

    func testHandshakeScoreAllPaidBack() {
        let loans = [
            Loan(friendName: "A", amount: 10, isPaidBack: true),
            Loan(friendName: "B", amount: 20, isPaidBack: true)
        ]
        let result = HandshakeCalculator.compute(loans: loans)
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.totalOutstanding, 0)
    }

    func testHandshakeScoreNonePaidBack() {
        let loans = [
            Loan(friendName: "A", amount: 10, isPaidBack: false),
            Loan(friendName: "B", amount: 20, isPaidBack: false)
        ]
        let result = HandshakeCalculator.compute(loans: loans)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.totalOutstanding, 30)
    }

    func testHandshakeScoreMixed() {
        let loans = [
            Loan(friendName: "A", amount: 10, isPaidBack: true),
            Loan(friendName: "B", amount: 20, isPaidBack: false)
        ]
        let result = HandshakeCalculator.compute(loans: loans)
        XCTAssertEqual(result.score, 50, accuracy: 0.001)
        XCTAssertEqual(result.totalOutstanding, 20)
    }

    func testHandshakeScoreEmptyDefaultsTo100() {
        let result = HandshakeCalculator.compute(loans: [])
        XCTAssertEqual(result.score, 100)
    }

    func testHandshakeStreakCountsFromMostRecent() {
        let now = Date()
        let loans = [
            Loan(friendName: "Old", amount: 10, dateLent: now.addingTimeInterval(-3000), isPaidBack: false),
            Loan(friendName: "Mid", amount: 10, dateLent: now.addingTimeInterval(-2000), isPaidBack: true),
            Loan(friendName: "Recent1", amount: 10, dateLent: now.addingTimeInterval(-1000), isPaidBack: true),
            Loan(friendName: "Recent2", amount: 10, dateLent: now, isPaidBack: true)
        ]
        let result = HandshakeCalculator.compute(loans: loans)
        // Most recent 3 are paid back consecutively, then the oldest breaks the streak.
        XCTAssertEqual(result.paidBackStreak, 3)
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        _ = store.addLoan(friendName: "Extra", amount: 5, note: "", isPro: true)
        store.deleteAllData()
        XCTAssertFalse(store.loans.isEmpty)
    }
}
