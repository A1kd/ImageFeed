import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    @IBOutlet private weak var tableView: UITableView!

    private var photos: [Photo] = []
    private var imagesListObserver: NSObjectProtocol?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        imagesListObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableViewAnimated()
        }

        ImagesListService.shared.fetchPhotosNextPage()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            viewController.imageURL = photos[indexPath.row].largeImageURL
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = ImagesListService.shared.photos.count
        photos = ImagesListService.shared.photos
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)

        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }

        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)

        return imageListCell
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]

        cell.setIsLiked(photo.isLiked)
        cell.dateLabel.text = photo.createdAt.map { dateFormatter.string(from: $0) } ?? ""

        guard let url = URL(string: photo.thumbImageURL) else {
            cell.setImageState(.error)
            return
        }

        cell.setImageState(.loading)
        cell.cellImage.kf.setImage(with: url) { [weak cell] result in
            switch result {
            case .success(let value):
                cell?.setImageState(.finished(value.image))
            case .failure:
                cell?.setImageState(.error)
            }
        }
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            ImagesListService.shared.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]

        UIBlockingProgressHUD.show()
        ImagesListService.shared.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            switch result {
            case .success:
                self.photos = ImagesListService.shared.photos
                cell.setIsLiked(self.photos[indexPath.row].isLiked)
            case .failure(let error):
                print("[imageListCellDidTapLike ImagesListViewController]: \(type(of: error)) - \(error.localizedDescription) photoId=\(photo.id)")
            }
        }
    }
}
