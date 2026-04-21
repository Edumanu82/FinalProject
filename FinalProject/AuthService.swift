//
//  AuthService.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import Foundation

enum AppConfiguration {
    static let firebase = FirebaseConfiguration.load()
}

struct FirebaseConfiguration {
    let apiKey: String
    let databaseURL: String
    let projectID: String

    static func load(bundle: Bundle = .main) -> FirebaseConfiguration {
        guard
            let url = bundle.url(forResource: "GoogleService-Info", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let rawValues = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            fatalError("GoogleService-Info.plist is missing from the app bundle.")
        }

        guard
            let apiKey = rawValues["API_KEY"] as? String,
            let databaseURL = rawValues["DATABASE_URL"] as? String,
            let projectID = rawValues["PROJECT_ID"] as? String
        else {
            fatalError("GoogleService-Info.plist is missing required Firebase keys.")
        }

        return FirebaseConfiguration(
            apiKey: apiKey,
            databaseURL: databaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
            projectID: projectID
        )
    }
}

enum AuthError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case emptyEmail
    case missingAuthToken
    case missingUserID

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Firebase configuration is missing or invalid."
        case .invalidResponse:
            return "The server response could not be read."
        case .emptyEmail:
            return "Firebase did not return an email for this account."
        case .missingAuthToken:
            return "Firebase did not return a valid user session."
        case .missingUserID:
            return "Firebase did not return a valid user id."
        }
    }
}

struct AstronomyAuthService {
    private let config = AppConfiguration.firebase

    func login(email: String, password: String) async throws -> UserProfile {
        let auth = try await performAuthRequest(
            endpoint: "accounts:signInWithPassword",
            payload: [
                "email": email,
                "password": password,
                "returnSecureToken": true
            ]
        )

        return try await loadUserProfile(from: auth)
    }

    func signUp(username: String, email: String, password: String) async throws -> UserProfile {
        let auth = try await performAuthRequest(
            endpoint: "accounts:signUp",
            payload: [
                "email": email,
                "password": password,
                "returnSecureToken": true
            ]
        )

        let profile = try makeProfile(from: auth, usernameOverride: username)
        try await saveUserProfile(profile, idToken: auth.idToken)
        return profile
    }

    private func performAuthRequest(endpoint: String, payload: [String: Any]) async throws -> FirebaseAuthPayload {
        guard !config.apiKey.isEmpty else {
            throw AuthError.invalidConfiguration
        }

        guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/\(endpoint)?key=\(config.apiKey)") else {
            throw AuthError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder().decode(FirebaseAuthPayload.self, from: data)
    }

    private func loadUserProfile(from auth: FirebaseAuthPayload) async throws -> UserProfile {
        let fallbackProfile = try makeProfile(from: auth, usernameOverride: nil)

        guard
            let idToken = auth.idToken,
            let localID = auth.localID,
            let url = URL(string: "\(config.databaseURL)/users/\(localID).json?auth=\(idToken)")
        else {
            return fallbackProfile
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response, data: data)

        let storedProfile = try JSONDecoder().decode(DatabaseUserProfile?.self, from: data)
        guard let storedProfile else {
            return fallbackProfile
        }

        return UserProfile(
            id: localID,
            username: storedProfile.username,
            email: storedProfile.email
        )
    }

    private func saveUserProfile(_ profile: UserProfile, idToken: String?) async throws {
        guard
            let idToken,
            !idToken.isEmpty,
            let url = URL(string: "\(config.databaseURL)/users/\(profile.id).json?auth=\(idToken)")
        else {
            throw AuthError.missingAuthToken
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            DatabaseUserProfile(username: profile.username, email: profile.email)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }

    private func makeProfile(from auth: FirebaseAuthPayload, usernameOverride: String?) throws -> UserProfile {
        guard let localID = auth.localID, !localID.isEmpty else {
            throw AuthError.missingUserID
        }

        guard let email = auth.email, !email.isEmpty else {
            throw AuthError.emptyEmail
        }

        let username = usernameOverride ?? auth.displayName ?? email.split(separator: "@").first.map(String.init) ?? "Explorer"

        return UserProfile(id: localID, username: username, email: email)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if let firebaseError = try? JSONDecoder().decode(FirebaseErrorEnvelope.self, from: data) {
                throw firebaseError.error
            }

            throw AuthError.invalidResponse
        }
    }
}

private struct FirebaseAuthPayload: Decodable {
    let idToken: String?
    let email: String?
    let localID: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case idToken
        case email
        case localID = "localId"
        case displayName
    }
}

private struct DatabaseUserProfile: Codable {
    let username: String
    let email: String
}

private struct FirebaseErrorEnvelope: Decodable {
    let error: FirebaseRequestError
}

private struct FirebaseRequestError: Decodable, Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        switch message {
        case "EMAIL_EXISTS":
            return "That email is already registered."
        case "EMAIL_NOT_FOUND", "INVALID_LOGIN_CREDENTIALS", "INVALID_PASSWORD":
            return "Incorrect email or password."
        case "WEAK_PASSWORD : Password should be at least 6 characters":
            return "Password must be at least 6 characters."
        case "USER_DISABLED":
            return "This account has been disabled."
        default:
            return message.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
