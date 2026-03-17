//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by I on 08.01.2026.
//

import UIKit

final class SplashViewController: UIViewController {

    private let tokenStorage = OAuth2TokenStorage()

    // MARK: - UI

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Vector")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuthStatus()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 73),
            logoImageView.heightAnchor.constraint(equalToConstant: 76)
        ])
    }

    // MARK: - Navigation

    private func checkAuthStatus() {
        if tokenStorage.token != nil {
            switchToFeedController()
        } else {
            showAuthViewController()
        }
    }

    private func showAuthViewController() {
        let authVC = AuthViewController()
        authVC.delegate = self
        authVC.modalPresentationStyle = .fullScreen
        present(authVC, animated: true)
    }

    private func switchToFeedController() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        let feedVC = ViewController()
        window.rootViewController = feedVC
        window.makeKeyAndVisible()
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) {
            self.switchToFeedController()
        }
    }
}
