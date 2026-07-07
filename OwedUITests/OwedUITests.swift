import XCTest

final class OwedUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsHandshakeMeterOnLaunch() throws {
        let app = launchApp()
        XCTAssertTrue(app.otherElements["handshakeGauge"].waitForExistence(timeout: 12), "Handshake gauge did not appear on launch")
    }

    func testSeedLoansAppear() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Alex"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Jamie"].waitForExistence(timeout: 6))
    }

    func testAddLoanFromHome() throws {
        let app = launchApp()
        // Seed data has 2 loans (free limit is 3), so add is still allowed.
        let addButton = app.buttons["addLoanButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["friendNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Taylor")

        let amountField = app.textFields["loanAmountField"]
        amountField.tap()
        amountField.typeText("25")

        app.buttons["saveLoanButton"].tap()

        XCTAssertTrue(app.staticTexts["Taylor"].waitForExistence(timeout: 12), "New loan did not appear")
    }

    func testLoanDetailShowsStatus() throws {
        let app = launchApp()
        let alexText = app.staticTexts["Alex"]
        XCTAssertTrue(alexText.waitForExistence(timeout: 12))
        alexText.tap()

        XCTAssertTrue(app.staticTexts["loanStatusLabel"].waitForExistence(timeout: 12), "Loan status did not appear in detail")
    }

    func testMarkPaidBackUpdatesBadge() throws {
        let app = launchApp()
        let alexText = app.staticTexts["Alex"]
        XCTAssertTrue(alexText.waitForExistence(timeout: 12))
        alexText.tap()

        let markPaidButton = app.buttons["markPaidBackButton"]
        XCTAssertTrue(markPaidButton.waitForExistence(timeout: 12))
        markPaidButton.tap()

        app.buttons["Done"].tap()

        let badge = app.staticTexts["loanBadge_Alex"]
        XCTAssertTrue(badge.waitForExistence(timeout: 12))
        XCTAssertEqual(badge.label, "Paid")
    }

    func testDeleteLoanFromDetail() throws {
        let app = launchApp()
        let alexText = app.staticTexts["Alex"]
        XCTAssertTrue(alexText.waitForExistence(timeout: 12))
        alexText.tap()

        app.buttons["deleteLoanButton"].tap()

        XCTAssertFalse(app.staticTexts["Alex"].waitForExistence(timeout: 6), "Loan was not deleted")
    }

    func testFreeLimitTriggersPaywallAtFourthLoan() throws {
        let app = launchApp()
        let addButton = app.buttons["addLoanButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["friendNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Taylor")
        let amountField = app.textFields["loanAmountField"]
        amountField.tap()
        amountField.typeText("25")
        app.buttons["saveLoanButton"].tap()

        XCTAssertTrue(app.staticTexts["Taylor"].waitForExistence(timeout: 12))

        // Now at the free limit (3 loans) — next add should show paywall.
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Owed Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free loan limit")
    }

    func testKeyboardDismissesOnTapOutside() throws {
        let app = launchApp()
        let addButton = app.buttons["addLoanButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["friendNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Test")
        XCTAssertTrue(app.keyboards.element.exists)

        // Tap on the form's section header, now given a name distinct from
        // the nav title ("Loan Details" vs "New Loan") so this query is
        // unambiguous — the earlier version reused the nav title text and
        // could resolve to that non-Form element via firstMatch instead.
        app.staticTexts["Loan Details"].tap()
        XCTAssertFalse(app.keyboards.element.exists, "Keyboard did not dismiss on tap-outside")
    }
}
