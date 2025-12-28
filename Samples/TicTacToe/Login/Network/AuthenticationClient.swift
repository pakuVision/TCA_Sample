//
//  AuthenticationClient.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/25.
//

import ComposableArchitecture
import Foundation

nonisolated
public struct AuthenticationResponse: Equatable, Sendable {
    public var token: String
    public var twoFactorRequired: Bool
    
    public init(token: String, twoFactorRequired: Bool) {
        self.token = token
        self.twoFactorRequired = twoFactorRequired
    }
}

nonisolated
public enum AuthenticationError: Equatable, LocalizedError, Sendable {
    case invalidUserPassword
    case invalidTwoFactor
    case invalidIntermediateToken
    
    public var errorDescription: String? {
        switch self {
        case .invalidUserPassword:
            return "Unknown user or invalid password"
        case .invalidTwoFactor:
          return "Invalid second factor (try 1234)"
        case .invalidIntermediateToken:
          return "404!! What happened to your token there bud?!?!"
        }
    }
}

@DependencyClient
public struct AuthenticationClient: Sendable {
    public var login: @Sendable (_ email: String, _ password: String) async throws -> AuthenticationResponse
    public var twoFactor: @Sendable (_ code: String, _ token: String) async throws -> AuthenticationResponse
}

extension DependencyValues {
    nonisolated
    public var authenticationClient: AuthenticationClient {
        get { self[AuthenticationClient.self] }
        set { self[AuthenticationClient.self] = newValue }
    }
}

extension AuthenticationClient: DependencyKey {
    public static let liveValue = AuthenticationClient(
        login: { email, password in
            guard email.contains("@") && password == "password" else { throw AuthenticationError.invalidUserPassword }
            
            try await Task.sleep(for: .seconds(2))
            return AuthenticationResponse(token: "test-token", twoFactorRequired: email.contains("2fa"))
        },
        twoFactor: { code, token in
            guard token == "test-token" else { throw AuthenticationError.invalidIntermediateToken }
            guard code == "1234" else { throw AuthenticationError.invalidTwoFactor }
            
            try await Task.sleep(for: .seconds(2))
            return AuthenticationResponse(token: "new-test-token", twoFactorRequired: false)
        }
    )
}

