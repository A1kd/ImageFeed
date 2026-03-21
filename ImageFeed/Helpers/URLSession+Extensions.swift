import Foundation

enum URLSessionError: Error {
    case invalidResponse
    case httpError(Int)
    case noData
}

extension URLSession {

    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionDataTask {
        let task = dataTask(with: request) { data, response, error in
            if let error {
                print("[URLSession]: NetworkError - \(error.localizedDescription)")
                Self.fulfillCompletionOnMainThread(with: .failure(error), completion: completion)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[URLSession]: InvalidResponse")
                Self.fulfillCompletionOnMainThread(
                    with: .failure(URLSessionError.invalidResponse),
                    completion: completion
                )
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("[URLSession]: HTTPError - \(httpResponse.statusCode)")
                Self.fulfillCompletionOnMainThread(
                    with: .failure(URLSessionError.httpError(httpResponse.statusCode)),
                    completion: completion
                )
                return
            }

            guard let data else {
                print("[URLSession]: NoData")
                Self.fulfillCompletionOnMainThread(
                    with: .failure(URLSessionError.noData),
                    completion: completion
                )
                return
            }

            Self.fulfillCompletionOnMainThread(with: .success(data), completion: completion)
        }
        return task
    }

    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionDataTask {
        return data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let object = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    print("[URLSession]: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private static func fulfillCompletionOnMainThread<T>(
        with result: Result<T, Error>,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
