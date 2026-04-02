//
//  AuthHelper.swift
//  ImageFeed
//

import Foundation

protocol AuthHelperProtocol {
    func authRequest() -> URLRequest?
    func code(from url: URL) -> String?
}

final class AuthHelper: AuthHelperProtocol {
    private let configuration: AuthConfiguration

    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }

    func authRequest() -> URLRequest? {
        guard let url = authURL() else { return nil }
        return URLRequest(url: url)
    }

    func authURL() -> URL? {
        let urlString = configuration.authURLString
            + "?client_id=\(configuration.accessKey)"
            + "&redirect_uri=\(configuration.redirectURI)"
            + "&response_type=code"
            + "&scope=\(configuration.accessScope)"
        return URL(string: urlString)
    }

    func code(from url: URL) -> String? {
        guard
            let components = URLComponents(string: url.absoluteString),
            let items = components.queryItems,
            let codeItem = items.first(where: { $0.name == "code" })
        else { return nil }
        return codeItem.value
    }
}
