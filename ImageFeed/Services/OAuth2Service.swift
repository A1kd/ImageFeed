import Foundation

enum OAuth2ServiceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case requestCancelled
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}

    private var currentTask: URLSessionTask?
    private var currentCode: String?
    private var completions: [(Result<String, Error>) -> Void] = []

    func fetchAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        // Тот же code — подписываемся на уже идущий запрос
        if currentCode == code {
            completions.append(completion)
            return
        }

        // Другой code — завершаем старый запрос с ошибкой отмены
        if currentTask != nil {
            let oldCompletions = completions
            resetState()
            oldCompletions.forEach { $0(.failure(OAuth2ServiceError.requestCancelled)) }
        }

        currentCode = code
        completions = [completion]

        guard var components = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service]: InvalidURL — не удалось создать URLComponents")
            finish(with: .failure(OAuth2ServiceError.invalidURL), for: code)
            return
        }

        components.queryItems = [
            URLQueryItem(name: "client_id",     value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri",  value: Constants.redirectURI),
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "grant_type",    value: "authorization_code")
        ]

        guard let url = components.url else {
            print("[OAuth2Service]: InvalidURL — не удалось собрать URL из компонентов")
            finish(with: .failure(OAuth2ServiceError.invalidURL), for: code)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                // Игнорируем ответ если запрос уже не актуален
                guard self.currentCode == code else { return }

                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    self.finish(with: .failure(OAuth2ServiceError.requestCancelled), for: code)
                    return
                }

                if let error {
                    print("[OAuth2Service]: NetworkError - \(error.localizedDescription)")
                    self.finish(with: .failure(error), for: code)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[OAuth2Service]: InvalidResponse")
                    self.finish(with: .failure(OAuth2ServiceError.invalidResponse), for: code)
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("[OAuth2Service]: HTTPError - \(httpResponse.statusCode)")
                    self.finish(with: .failure(OAuth2ServiceError.httpError(httpResponse.statusCode)), for: code)
                    return
                }

                guard let data else {
                    print("[OAuth2Service]: NoData")
                    self.finish(with: .failure(OAuth2ServiceError.noData), for: code)
                    return
                }

                do {
                    let body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                    self.finish(with: .success(body.accessToken), for: code)
                } catch {
                    print("[OAuth2Service]: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    self.finish(with: .failure(error), for: code)
                }
            }
        }

        currentTask = task
        task.resume()
    }

    // MARK: - Private

    private func finish(with result: Result<String, Error>, for code: String) {
        guard currentCode == code else { return }
        let callbacks = completions
        resetState()
        callbacks.forEach { $0(result) }
    }

    private func resetState() {
        currentTask?.cancel()
        currentTask = nil
        currentCode = nil
        completions.removeAll()
    }
}
