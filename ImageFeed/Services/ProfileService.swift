import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private(set) var profile: Profile?

    nonisolated(unsafe) private var currentTask: URLSessionDataTask?

    nonisolated func fetchProfile(_ token: String, completion: @escaping @Sendable (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        currentTask?.cancel()

        guard let url = URL(string: Constants.defaultBaseURLString + "/me") else {
            print("[ProfileService]: InvalidURL")
            completion(.failure(URLSessionError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self else { return }
            self.currentTask = nil

            switch result {
            case .success(let profileResult):
                let profile = Profile(result: profileResult)
                self.profile = profile
                completion(.success(profile))
            case .failure(let error):
                print("[ProfileService]: \(type(of: error)) – \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        currentTask = task
        task.resume()
    }
}
