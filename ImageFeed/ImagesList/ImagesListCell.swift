import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    // MARK: - IBOutlets

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!

    // MARK: - Properties

    weak var delegate: ImagesListCellDelegate?
    private var gradientLayer: CAGradientLayer?

    // MARK: - UI

    private lazy var stubIconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        let image = UIImage(systemName: "scribble.variable", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = UIColor(white: 0.55, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        likeButton.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)
        setupStubIcon()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        removeGradient()
        cellImage.backgroundColor = .clear
        cellImage.image = nil
        stubIconView.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = cellImage.bounds
    }

    // MARK: - Public Methods

    func setIsLiked(_ isLiked: Bool) {
        let imageName = isLiked ? "like_button_on" : "like_button_off"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
    }

    func setImageState(_ state: FeedCellImageState) {
        switch state {
        case .loading:
            cellImage.image = nil
            cellImage.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
            stubIconView.isHidden = false
            showGradient()
        case .error:
            removeGradient()
            cellImage.backgroundColor = .clear
            cellImage.image = nil
            stubIconView.isHidden = true
        case .finished(let image):
            removeGradient()
            cellImage.backgroundColor = .clear
            cellImage.image = image
            stubIconView.isHidden = true
        }
    }

    // MARK: - Actions

    @IBAction private func didTapLikeButton() {
        delegate?.imageListCellDidTapLike(self)
    }

    // MARK: - Private Methods

    private func setupStubIcon() {
        cellImage.addSubview(stubIconView)
        NSLayoutConstraint.activate([
            stubIconView.centerXAnchor.constraint(equalTo: cellImage.centerXAnchor),
            stubIconView.centerYAnchor.constraint(equalTo: cellImage.centerYAnchor),
            stubIconView.widthAnchor.constraint(equalToConstant: 83),
            stubIconView.heightAnchor.constraint(equalToConstant: 83)
        ])
    }

    private func showGradient() {
        guard gradientLayer == nil else { return }
        let gradient = CAGradientLayer()
        gradient.frame = cellImage.bounds
        gradient.locations = [0, 0.1, 0.3]
        gradient.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = cellImage.layer.cornerRadius
        gradient.masksToBounds = true

        // Insert below stubIconView so the icon stays on top
        cellImage.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        let animation = CABasicAnimation(keyPath: "locations")
        animation.duration = 1.0
        animation.repeatCount = .infinity
        animation.fromValue = [0, 0.1, 0.3]
        animation.toValue = [0, 0.8, 1]
        gradient.add(animation, forKey: "locationsChange")
    }

    private func removeGradient() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
    }
}
