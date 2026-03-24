import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    @IBOutlet private var tableView: UITableView!

    var presenter: ImagesListPresenterProtocol?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.accessibilityIdentifier = "tableView"

        if presenter == nil {
            presenter = ImagesListPresenter()
        }
        presenter?.view = self
        presenter?.viewDidLoad()
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
            viewController.imageURL = presenter?.photo(at: indexPath.row).largeImageURL
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - ImagesListViewProtocol

extension ImagesListViewController: ImagesListViewProtocol {
    func updateTableViewAnimated(from oldCount: Int, to newCount: Int) {
        guard oldCount != newCount else { return }
        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
}

// MARK: - UITableViewDataSource

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter?.photosCount ?? 0
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
        guard let photo = presenter?.photo(at: indexPath.row) else { return }

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

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let photo = presenter?.photo(at: indexPath.row) else { return 0 }
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter?.fetchNextPageIfNeeded(for: indexPath.row)
    }
}

// MARK: - ImagesListCellDelegate

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        UIBlockingProgressHUD.show()
        presenter?.changeLike(at: indexPath.row) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            switch result {
            case .success:
                if let photo = self.presenter?.photo(at: indexPath.row) {
                    cell.setIsLiked(photo.isLiked)
                }
            case .failure(let error):
                print("[imageListCellDidTapLike ImagesListViewController]: \(type(of: error)) - \(error.localizedDescription)")
            }
        }
    }
}
