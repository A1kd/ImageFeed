//
//  ProfilePresenter.swift
//  ImageFeed
//

import Foundation

protocol ProfileViewProtocol: AnyObject {
    func updateAvatar(url: URL)
    func updateProfileDetails(name: String, loginName: String, bio: String)
    func showLogoutConfirmation()
    func resetToSplash()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
    func logout()
}

// MARK: - Service protocols (for testability)

protocol ProfileServiceProtocol {
    var profile: Profile? { get }
}

protocol ProfileImageServiceProtocol {
    var avatarURL: String? { get }
}

extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}

// MARK: - Presenter

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?

    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol

    init(
        profileService: ProfileServiceProtocol = ProfileService.shared,
        profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
    }

    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.updateProfileDetails(
                name: profile.name,
                loginName: profile.loginName,
                bio: profile.bio ?? ""
            )
        }
        updateAvatar()
        observeAvatarChange()
    }

    func didTapLogout() {
        view?.showLogoutConfirmation()
    }

    func logout() {
        OAuth2TokenStorage.shared.token = nil
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)

        ImagesListService.shared.reset()
        ProfileService.shared.reset()
        ProfileImageService.shared.reset()

        view?.resetToSplash()
    }

    // MARK: - Private

    private func updateAvatar() {
        guard
            let urlString = profileImageService.avatarURL,
            let url = URL(string: urlString)
        else { return }
        view?.updateAvatar(url: url)
    }

    private func observeAvatarChange() {
        NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
    }
}
