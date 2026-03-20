import Foundation

enum ProfileServiceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
}

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
            DispatchQueue.main.async { completion(.failure(ProfileServiceError.invalidURL)) }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                print("[ProfileService]: NetworkError - \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ProfileService]: InvalidResponse")
                DispatchQueue.main.async { completion(.failure(ProfileServiceError.invalidResponse)) }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("[ProfileService]: HTTPError - код ошибки \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(ProfileServiceError.httpError(httpResponse.statusCode)))
                }
                return
            }

            guard let data else {
                print("[ProfileService]: NoData")
                DispatchQueue.main.async { completion(.failure(ProfileServiceError.noData)) }
                return
            }

            do {
                let result = try JSONDecoder().decode(ProfileResult.self, from: data)
                let profile = Profile(result: result)
                DispatchQueue.main.async {
                    self?.profile = profile
                    completion(.success(profile))
                }
            } catch {
                print("[ProfileService]: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "nil")")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        currentTask = task
        task.resume()
    }
}
