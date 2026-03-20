import UIKit

final class SplashViewController: UIViewController {

    // MARK: - UI

    private lazy var logoImageView: UIImageView = {
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
        if let token = OAuth2TokenStorage.shared.token {
            fetchProfile(token: token)
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

    private func fetchProfile(token: String) {
        ProfileService.shared.fetchProfile(token) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImageURL(
                    username: profile.username,
                    token: token
                ) { [weak self] _ in
                    self?.switchToTabBarController()
                }
            case .failure(let error):
                print("[SplashViewController]: fetchProfile failure - \(error.localizedDescription)")
                self.switchToTabBarController()
            }
        }
    }

    private func switchToTabBarController() {
        guard
            let scene  = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first
        else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let tabBarVC   = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        window.rootViewController = tabBarVC
        window.makeKeyAndVisible()
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let token = OAuth2TokenStorage.shared.token else { return }
            self?.fetchProfile(token: token)
        }
    }
}
