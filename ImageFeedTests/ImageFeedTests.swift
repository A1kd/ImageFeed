//
//  ImageFeedTests.swift
//  ImageFeedTests
//

import XCTest
@testable import ImageFeed

// MARK: - WebView Tests

final class WebViewTests: XCTestCase {

    /// Проверяет, что presenter вызывает loadRequest у view после viewDidLoad()
    func testPresenterCallsLoadRequest() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let viewSpy = WebViewViewControllerSpy()
        presenter.view = viewSpy
        viewSpy.presenter = presenter

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(viewSpy.loadRequestCalled, "Presenter должен вызывать load(request:) при viewDidLoad")
    }

    /// Если прогресс равен 1, метод shouldHideProgress возвращает true
    func testProgressHiddenWhenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)

        // when
        let shouldHide = presenter.shouldHideProgress(for: 1.0)

        // then
        XCTAssertTrue(shouldHide, "Прогресс-бар должен скрываться при значении 1.0")
    }

    /// Проверяет, что AuthHelper корректно извлекает код авторизации из URL
    func testCodeFromURL() {
        // given
        let authHelper = AuthHelper()
        let expectedCode = "test_auth_code_12345"
        let urlString = "https://unsplash.com/oauth/callback?code=\(expectedCode)"
        guard let url = URL(string: urlString) else {
            XCTFail("Не удалось создать URL")
            return
        }

        // when
        let code = authHelper.code(from: url)

        // then
        XCTAssertEqual(code, expectedCode, "AuthHelper должен корректно извлекать код из URL")
    }

    /// Проверяет, что AuthHelper возвращает nil, если код отсутствует
    func testCodeFromURLReturnsNilWhenAbsent() {
        let authHelper = AuthHelper()
        let url = URL(string: "https://unsplash.com/oauth/callback?error=access_denied")!
        XCTAssertNil(authHelper.code(from: url))
    }

    /// Проверяет, что прогресс не скрывается при значении < 1
    func testProgressNotHiddenWhenLessThanOne() {
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        XCTAssertFalse(presenter.shouldHideProgress(for: 0.5))
    }
}

// MARK: - WebViewViewControllerSpy

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    var loadRequestCalled = false
    var lastRequest: URLRequest?

    func load(request: URLRequest) {
        loadRequestCalled = true
        lastRequest = request
    }

    func setProgressValue(_ newValue: Float) {}
    func setProgressHidden(_ isHidden: Bool) {}
}

// MARK: - Profile Tests

final class ProfilePresenterTests: XCTestCase {

    /// Проверяет, что presenter корректно передаёт данные профиля в view
    func testPresenterUpdatesViewWithProfile() {
        // given
        let mockService = MockProfileService()
        mockService.mockProfile = Profile(
            result: ProfileResult(
                username: "test_user",
                firstName: "Test",
                lastName: "User",
                bio: "Test bio"
            )
        )
        let mockImageService = MockProfileImageService()
        let presenter = ProfilePresenter(
            profileService: mockService,
            profileImageService: mockImageService
        )
        let viewSpy = ProfileViewSpy()
        presenter.view = viewSpy

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(viewSpy.updateProfileDetailsCalled, "Presenter должен вызвать updateProfileDetails")
        XCTAssertEqual(viewSpy.capturedName, "Test User")
        XCTAssertEqual(viewSpy.capturedLoginName, "@test_user")
        XCTAssertEqual(viewSpy.capturedBio, "Test bio")
    }

    /// Проверяет, что при отсутствии профиля updateProfileDetails не вызывается
    func testPresenterDoesNotUpdateViewWhenNoProfile() {
        // given
        let mockService = MockProfileService()
        mockService.mockProfile = nil
        let presenter = ProfilePresenter(
            profileService: mockService,
            profileImageService: MockProfileImageService()
        )
        let viewSpy = ProfileViewSpy()
        presenter.view = viewSpy

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertFalse(viewSpy.updateProfileDetailsCalled)
    }

    /// Проверяет, что нажатие кнопки логаута вызывает showLogoutConfirmation у view
    func testLogoutTapShowsConfirmation() {
        // given
        let presenter = ProfilePresenter(
            profileService: MockProfileService(),
            profileImageService: MockProfileImageService()
        )
        let viewSpy = ProfileViewSpy()
        presenter.view = viewSpy

        // when
        presenter.didTapLogout()

        // then
        XCTAssertTrue(viewSpy.showLogoutConfirmationCalled)
    }
}

// MARK: - Profile Mocks & Spies

final class MockProfileService: ProfileServiceProtocol {
    var mockProfile: Profile?
    var profile: Profile? { mockProfile }
}

final class MockProfileImageService: ProfileImageServiceProtocol {
    var mockAvatarURL: String?
    var avatarURL: String? { mockAvatarURL }
}

final class ProfileViewSpy: ProfileViewProtocol {
    var updateProfileDetailsCalled = false
    var capturedName: String?
    var capturedLoginName: String?
    var capturedBio: String?
    var showLogoutConfirmationCalled = false
    var resetToSplashCalled = false

    func updateProfileDetails(name: String, loginName: String, bio: String) {
        updateProfileDetailsCalled = true
        capturedName = name
        capturedLoginName = loginName
        capturedBio = bio
    }

    func updateAvatar(url: URL) {}
    func showLogoutConfirmation() { showLogoutConfirmationCalled = true }
    func resetToSplash() { resetToSplashCalled = true }
}

// MARK: - ImagesList Tests

final class ImagesListPresenterTests: XCTestCase {

    /// Проверяет, что photosCount возвращает корректное количество фотографий
    func testPhotosCountMatchesService() {
        // given
        let mockService = MockImagesListService()
        mockService.mockPhotos = [
            makePhoto(id: "1"),
            makePhoto(id: "2"),
            makePhoto(id: "3")
        ]
        let presenter = ImagesListPresenter(imagesListService: mockService)

        // then
        XCTAssertEqual(presenter.photosCount, 3)
    }

    /// Проверяет, что presenter возвращает корректное фото по индексу
    func testPhotoAtIndexReturnsCorrectPhoto() {
        // given
        let mockService = MockImagesListService()
        let expectedPhoto = makePhoto(id: "photo_42")
        mockService.mockPhotos = [makePhoto(id: "1"), expectedPhoto, makePhoto(id: "3")]
        let presenter = ImagesListPresenter(imagesListService: mockService)

        // when
        let photo = presenter.photo(at: 1)

        // then
        XCTAssertEqual(photo.id, "photo_42")
    }

    /// Проверяет, что viewDidLoad запускает загрузку первой страницы
    func testViewDidLoadFetchesNextPage() {
        // given
        let mockService = MockImagesListService()
        let presenter = ImagesListPresenter(imagesListService: mockService)
        let viewSpy = ImagesListViewSpy()
        presenter.view = viewSpy

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(mockService.fetchPhotosNextPageCalled)
    }

    /// Проверяет, что fetchNextPageIfNeeded вызывает загрузку при последней ячейке
    func testFetchNextPageIfNeededOnLastRow() {
        // given
        let mockService = MockImagesListService()
        mockService.mockPhotos = [makePhoto(id: "1"), makePhoto(id: "2")]
        let presenter = ImagesListPresenter(imagesListService: mockService)

        // when — сбрасываем флаг после viewDidLoad (если нужно)
        mockService.fetchPhotosNextPageCalled = false
        presenter.fetchNextPageIfNeeded(for: 1) // last index = count - 1 = 1

        // then
        XCTAssertTrue(mockService.fetchPhotosNextPageCalled)
    }

    // MARK: - Helper

    private func makePhoto(id: String) -> Photo {
        Photo(
            id: id,
            size: CGSize(width: 100, height: 100),
            createdAt: nil,
            welcomeDescription: nil,
            thumbImageURL: "",
            largeImageURL: "",
            isLiked: false
        )
    }
}

// MARK: - ImagesList Mocks & Spies

final class MockImagesListService: ImagesListServiceProtocol {
    var mockPhotos: [Photo] = []
    var photos: [Photo] { mockPhotos }
    var fetchPhotosNextPageCalled = false

    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}

final class ImagesListViewSpy: ImagesListViewProtocol {
    var updateTableViewAnimatedCalled = false

    func updateTableViewAnimated(from oldCount: Int, to newCount: Int) {
        updateTableViewAnimatedCalled = true
    }
}
