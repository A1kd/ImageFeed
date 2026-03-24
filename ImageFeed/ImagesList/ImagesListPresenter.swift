//
//  ImagesListPresenter.swift
//  ImageFeed
//

import Foundation

protocol ImagesListViewProtocol: AnyObject {
    func updateTableViewAnimated(from oldCount: Int, to newCount: Int)
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewProtocol? { get set }
    var photosCount: Int { get }
    func viewDidLoad()
    func fetchNextPageIfNeeded(for rowIndex: Int)
    func photo(at index: Int) -> Photo
    func changeLike(at index: Int, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Service protocol (for testability)

protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

extension ImagesListService: ImagesListServiceProtocol {}

// MARK: - Presenter

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?

    private let imagesListService: ImagesListServiceProtocol
    private var imagesListObserver: NSObjectProtocol?
    private var currentPhotosCount: Int = 0

    var photosCount: Int {
        imagesListService.photos.count
    }

    init(imagesListService: ImagesListServiceProtocol = ImagesListService.shared) {
        self.imagesListService = imagesListService
    }

    func viewDidLoad() {
        currentPhotosCount = imagesListService.photos.count

        imagesListObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let newCount = self.imagesListService.photos.count
            self.view?.updateTableViewAnimated(from: self.currentPhotosCount, to: newCount)
            self.currentPhotosCount = newCount
        }

        imagesListService.fetchPhotosNextPage()
    }

    func fetchNextPageIfNeeded(for rowIndex: Int) {
        if rowIndex + 1 == imagesListService.photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }

    func photo(at index: Int) -> Photo {
        imagesListService.photos[index]
    }

    func changeLike(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let photo = imagesListService.photos[index]
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked, completion)
    }
}
