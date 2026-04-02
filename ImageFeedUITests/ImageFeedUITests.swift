//
//  ImageFeedUITests.swift
//  ImageFeedUITests
//

import XCTest

final class ImageFeedUITests: XCTestCase {

    private let app = XCUIApplication()

    // MARK: - Credentials
    // Данные задаются через Edit Scheme → Test → Arguments → Environment Variables:
    // TEST_LOGIN, TEST_PASSWORD, TEST_NAME, TEST_LOGIN_NAME
    private let testLogin     = ProcessInfo.processInfo.environment["TEST_LOGIN"] ?? ""
    private let testPassword  = ProcessInfo.processInfo.environment["TEST_PASSWORD"] ?? ""
    private let testName      = ProcessInfo.processInfo.environment["TEST_NAME"] ?? ""
    private let testLoginName = ProcessInfo.processInfo.environment["TEST_LOGIN_NAME"] ?? ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - testAuth

    @MainActor
    func testAuth() throws {
        // Нажать кнопку авторизации
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
        authButton.tap()

        // Подождать, пока экран авторизации открывается и загружается
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15))

        // Ввести логин
        let loginField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginField.waitForExistence(timeout: 10))
        loginField.tap()
        loginField.typeText(testLogin)

        // Нажать на следующее поле (пароль)
        let passwordField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(testPassword)

        // Нажать кнопку логина
        let loginButton = webView.buttons["Sign In"]
        if loginButton.waitForExistence(timeout: 5) {
            loginButton.tap()
        } else {
            // Альтернативный вариант — кнопка «Allow» или «Authorize»
            let authorizeButton = webView.buttons["Allow"]
            if authorizeButton.waitForExistence(timeout: 5) {
                authorizeButton.tap()
            }
        }

        // Подождать, пока открывается экран ленты
        let tableView = app.tables["tableView"]
        XCTAssertTrue(tableView.waitForExistence(timeout: 20))
    }

    // MARK: - testFeed

    @MainActor
    func testFeed() throws {
        // Подождать, пока открывается и загружается экран ленты
        let tableView = app.tables["tableView"]
        XCTAssertTrue(tableView.waitForExistence(timeout: 10))

        // Сделать жест «смахивания» вверх по экрану для скролла
        tableView.swipeUp()

        // Получить первую ячейку
        let firstCell = tableView.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))

        // Поставить лайк в ячейке верхней картинки
        let likeButton = firstCell.buttons["likeButton"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 5))
        likeButton.tap()
        sleep(2)

        // Отменить лайк в ячейке верхней картинки
        likeButton.tap()
        sleep(2)

        // Нажать на верхнюю ячейку
        firstCell.tap()

        // Подождать, пока картинка открывается на весь экран
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 10))

        // Увеличить картинку (pinch in)
        image.pinch(withScale: 3, velocity: 1)
        sleep(1)

        // Уменьшить картинку (pinch out)
        image.pinch(withScale: 0.5, velocity: -1)
        sleep(1)

        // Вернуться на экран ленты
        let backButton = app.buttons["backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()

        XCTAssertTrue(tableView.waitForExistence(timeout: 5))
    }

    // MARK: - testProfile

    @MainActor
    func testProfile() throws {
        // Подождать, пока открывается и загружается экран ленты
        let tableView = app.tables["tableView"]
        XCTAssertTrue(tableView.waitForExistence(timeout: 10))

        // Перейти на экран профиля
        app.tabBars.buttons.element(boundBy: 1).tap()

        // Проверить, что на нём отображаются персональные данные
        let nameLabel = app.staticTexts["nameLabel"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(nameLabel.label, testName)

        let loginLabel = app.staticTexts["loginLabel"]
        XCTAssertTrue(loginLabel.exists)
        XCTAssertEqual(loginLabel.label, testLoginName)

        // Нажать кнопку логаута
        let logoutButton = app.buttons["logout button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 3))
        logoutButton.tap()

        // Подтвердить логаут
        let confirmButton = app.alerts.buttons["Да"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3))
        confirmButton.tap()

        // Проверить, что открылся экран авторизации
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10))
    }
}
