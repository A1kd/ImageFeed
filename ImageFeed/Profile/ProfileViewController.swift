import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {

    // MARK: - UI Elements

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Stub")
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "logout_button"), for: .normal)
        button.tintColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "logout button"
        return button
    }()

    // MARK: - Shimmer state

    private var avatarGradientLayer: CAGradientLayer?
    private var labelShimmerViews: [UIView] = []
    // Fixed shimmer bar sizes from design [width, height]
    private let shimmerSizes: [(CGFloat, CGFloat)] = [(150, 28), (104, 18), (80, 18)]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        showAllShimmers()
        updateProfileDetails()
        observeAvatarChange()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarGradientLayer?.frame = profileImageView.bounds
        for shimmerView in labelShimmerViews {
            guard let gradient = shimmerView.layer.sublayers?.first as? CAGradientLayer else { continue }
            gradient.frame = shimmerView.bounds
            gradient.cornerRadius = shimmerView.layer.cornerRadius
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0x1A/255.0, green: 0x1B/255.0, blue: 0x22/255.0, alpha: 1.0)
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(logoutButton)
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            loginNameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            descriptionLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Profile Data

    private func updateProfileDetails() {
        guard let profile = ProfileService.shared.profile else { return }
        nameLabel.text        = profile.name
        loginNameLabel.text   = profile.loginName
        descriptionLabel.text = profile.bio ?? ""
        removeLabelShimmers()
    }

    private func observeAvatarChange() {
        NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
        updateAvatar()
    }

    private func updateAvatar() {
        guard
            let urlString = ProfileImageService.shared.avatarURL,
            let url = URL(string: urlString)
        else {
            showAvatarGradient()
            return
        }
        profileImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "Stub")
        ) { [weak self] _ in
            self?.removeAvatarGradient()
        }
    }

    // MARK: - All shimmers (called on load)

    private func showAllShimmers() {
        showAvatarGradient()
        showLabelShimmers()
    }

    // MARK: - Avatar shimmer

    private func showAvatarGradient() {
        guard avatarGradientLayer == nil else { return }
        let gradient = makeShimmerLayer(cornerRadius: 35)
        gradient.frame = profileImageView.bounds
        profileImageView.layer.addSublayer(gradient)
        avatarGradientLayer = gradient
    }

    private func removeAvatarGradient() {
        avatarGradientLayer?.removeFromSuperlayer()
        avatarGradientLayer = nil
    }

    // MARK: - Label shimmers

    private func showLabelShimmers() {
        guard labelShimmerViews.isEmpty else { return }
        let anchors: [(topAnchor: NSLayoutYAxisAnchor, leadingAnchor: NSLayoutXAxisAnchor)] = [
            (nameLabel.topAnchor, nameLabel.leadingAnchor),
            (loginNameLabel.topAnchor, loginNameLabel.leadingAnchor),
            (descriptionLabel.topAnchor, descriptionLabel.leadingAnchor)
        ]

        for (index, anchor) in anchors.enumerated() {
            let (width, height) = shimmerSizes[index]
            let shimmerView = UIView()
            shimmerView.translatesAutoresizingMaskIntoConstraints = false
            shimmerView.layer.cornerRadius = 9
            shimmerView.clipsToBounds = true
            view.addSubview(shimmerView)
            labelShimmerViews.append(shimmerView)

            NSLayoutConstraint.activate([
                shimmerView.leadingAnchor.constraint(equalTo: anchor.leadingAnchor),
                shimmerView.topAnchor.constraint(equalTo: anchor.topAnchor),
                shimmerView.widthAnchor.constraint(equalToConstant: width),
                shimmerView.heightAnchor.constraint(equalToConstant: height)
            ])

            let gradient = makeShimmerLayer(cornerRadius: 9)
            shimmerView.layer.addSublayer(gradient)
        }
    }

    private func removeLabelShimmers() {
        labelShimmerViews.forEach { $0.removeFromSuperview() }
        labelShimmerViews.removeAll()
    }

    // MARK: - Shared gradient factory

    private func makeShimmerLayer(cornerRadius: CGFloat) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.locations = [0, 0.1, 0.3]
        gradient.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = cornerRadius
        gradient.masksToBounds = true

        let animation = CABasicAnimation(keyPath: "locations")
        animation.duration    = 1.0
        animation.repeatCount = .infinity
        animation.fromValue   = [0, 0.1, 0.3]
        animation.toValue     = [0, 0.8, 1]
        gradient.add(animation, forKey: "locationsChange")
        return gradient
    }

    // MARK: - Actions

    @objc private func didTapLogoutButton() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены что хотите выйти?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel))
        alert.addAction(UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        OAuth2TokenStorage.shared.token = nil
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()

        ImagesListService.shared.reset()
        ProfileService.shared.reset()
        ProfileImageService.shared.reset()

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first
        else { return }

        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
    }
}
