import Foundation

enum OAuth2ServiceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}

    nonisolated(unsafe) private var currentTask: URLSessionDataTask?
    nonisolated(unsafe) private var lastCode: String?

    nonisolated func fetchAuthToken(
        code: String,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        guard lastCode != code else {
            print("[OAuth2Service]: Duplicate request for the same code — ignored")
            return
        }

        currentTask?.cancel()
        lastCode = code

        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service]: InvalidURL")
            DispatchQueue.main.async { [weak self] in
                self?.lastCode = nil
                completion(.failure(OAuth2ServiceError.invalidURL))
            }
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id",     value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri",  value: Constants.redirectURI),
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "grant_type",    value: "authorization_code")
        ]

        guard let url = urlComponents.url else {
            print("[OAuth2Service]: InvalidURL — failed to build from components")
            DispatchQueue.main.async { [weak self] in
                self?.lastCode = nil
                completion(.failure(OAuth2ServiceError.invalidURL))
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.lastCode = nil
                self?.currentTask = nil

                if let error {
                    print("[OAuth2Service]: NetworkError - \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[OAuth2Service]: InvalidResponse")
                    completion(.failure(OAuth2ServiceError.invalidResponse))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("[OAuth2Service]: HTTPError - код ошибки \(httpResponse.statusCode)")
                    completion(.failure(OAuth2ServiceError.httpError(httpResponse.statusCode)))
                    return
                }

                guard let data else {
                    print("[OAuth2Service]: NoData")
                    completion(.failure(OAuth2ServiceError.noData))
                    return
                }

                do {
                    let body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(body.accessToken))
                } catch {
                    print("[OAuth2Service]: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(error))
                }
            }
        }
        currentTask = task
        task.resume()
    }
}
