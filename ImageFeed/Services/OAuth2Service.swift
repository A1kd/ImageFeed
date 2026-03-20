//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by I on 08.01.2026.
//

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

    nonisolated func fetchAuthToken(
        code: String,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("OAuth2Service: Failed to create URLComponents")
            DispatchQueue.main.async { completion(.failure(OAuth2ServiceError.invalidURL)) }
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = urlComponents.url else {
            print("OAuth2Service: Failed to build URL from components")
            DispatchQueue.main.async { completion(.failure(OAuth2ServiceError.invalidURL)) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("OAuth2Service: Network error — \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("OAuth2Service: Invalid response type")
                DispatchQueue.main.async { completion(.failure(OAuth2ServiceError.invalidResponse)) }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("OAuth2Service: HTTP error — status \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.httpError(httpResponse.statusCode)))
                }
                return
            }

            guard let data else {
                print("OAuth2Service: No data received")
                DispatchQueue.main.async { completion(.failure(OAuth2ServiceError.noData)) }
                return
            }

            do {
                let body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                DispatchQueue.main.async { completion(.success(body.accessToken)) }
            } catch {
                print("OAuth2Service: JSON decoding error — \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        task.resume()
    }
}
