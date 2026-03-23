import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var currentTask: URLSessionDataTask?

    private init() {}

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        photos = []
        lastLoadedPage = nil
    }

    func fetchPhotosNextPage() {
        guard currentTask == nil else { return }

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[fetchPhotosNextPage ImagesListService]: NoToken page=\(nextPage)")
            return
        }

        guard var urlComponents = URLComponents(string: Constants.defaultBaseURLString + "/photos") else {
            print("[fetchPhotosNextPage ImagesListService]: InvalidBaseURL page=\(nextPage)")
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(nextPage)"),
            URLQueryItem(name: "per_page", value: "10")
        ]

        guard let url = urlComponents.url else {
            print("[fetchPhotosNextPage ImagesListService]: InvalidURL page=\(nextPage)")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            self.currentTask = nil

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { Photo(from: $0) }
                DispatchQueue.main.async {
                    self.photos += newPhotos
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                }
            case .failure(let error):
                print("[fetchPhotosNextPage ImagesListService]: \(type(of: error)) - \(error.localizedDescription) page=\(nextPage)")
            }
        }

        currentTask = task
        task.resume()
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[changeLike ImagesListService]: NoToken photoId=\(photoId)")
            return
        }

        let urlString = Constants.defaultBaseURLString + "/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            print("[changeLike ImagesListService]: InvalidURL photoId=\(photoId)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        self.photos[index] = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            isLiked: !photo.isLiked
                        )
                    }
                    completion(.success(()))
                }
            case .failure(let error):
                print("[changeLike ImagesListService]: \(type(of: error)) - \(error.localizedDescription) photoId=\(photoId)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
