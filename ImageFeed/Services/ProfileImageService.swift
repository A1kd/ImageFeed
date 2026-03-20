import Foundation

enum ProfileImageServiceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}

    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")

    private(set) var avatarURL: String?

    nonisolated(unsafe) private var currentTask: URLSessionDataTask?

    nonisolated func fetchProfileImageURL(
        username: String,
        token: String,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        currentTask?.cancel()

        guard let url = URL(string: Constants.defaultBaseURLString + "/users/\(username)") else {
            print("[ProfileImageService]: InvalidURL - username: \(username)")
            DispatchQueue.main.async { completion(.failure(ProfileImageServiceError.invalidURL)) }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                print("[ProfileImageService]: NetworkError - \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ProfileImageService]: InvalidResponse")
                DispatchQueue.main.async { completion(.failure(ProfileImageServiceError.invalidResponse)) }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("[ProfileImageService]: HTTPError - код ошибки \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(ProfileImageServiceError.httpError(httpResponse.statusCode)))
                }
                return
            }

            guard let data else {
                print("[ProfileImageService]: NoData")
                DispatchQueue.main.async { completion(.failure(ProfileImageServiceError.noData)) }
                return
            }

            do {
                let result = try JSONDecoder().decode(UserResult.self, from: data)
                let avatarURLString = result.profileImage.small
                DispatchQueue.main.async {
                    self?.avatarURL = avatarURLString
                    completion(.success(avatarURLString))
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": avatarURLString]
                    )
                }
            } catch {
                print("[ProfileImageService]: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "nil")")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        currentTask = task
        task.resume()
    }
}
