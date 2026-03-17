//
//  OAuth2TokenStorage.swift
//  ImageFeed
//
//  Created by I on 08.01.2026.
//

import Foundation

final class OAuth2TokenStorage {
    private let tokenKey = "bearerToken"

    nonisolated var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }
}
