import Foundation

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}

    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")

    private(set) var avatarURL: String?

    nonisolated(unsafe) private var currentTask: URLSessionDataTask?

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        avatarURL = nil
    }

    nonisolated func fetchProfileImageURL(
        username: String,
        token: String,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        currentTask?.cancel()

        guard let url = URL(string: Constants.defaultBaseURLString + "/users/\(username)") else {
            print("[ProfileImageService]: InvalidURL – username: \(username)")
            completion(.failure(URLSessionError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }
            self.currentTask = nil

            switch result {
            case .success(let userResult):
                let avatarURLString = userResult.profileImage.small
                self.avatarURL = avatarURLString
                completion(.success(avatarURLString))
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": avatarURLString]
                )
            case .failure(let error):
                print("[ProfileImageService]: \(type(of: error)) – \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        currentTask = task
        task.resume()
    }
}
