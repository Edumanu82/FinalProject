//
//  AuthService.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import Foundation

// Keep the backend URL empty until the real database/API is ready.
enum AppConfiguration {
    static let databaseURL = ""

    static var astronomyApplicationID: String {
        configuredValue(
            environmentKey: "ASTRONOMY_APPLICATION_ID",
            infoKey: "AstronomyApplicationID"
        )
    }

    static var astronomyApplicationSecret: String {
        configuredValue(
            environmentKey: "ASTRONOMY_APPLICATION_SECRET",
            infoKey: "AstronomyApplicationSecret"
        )
    }

    static var hasAstronomyCredentials: Bool {
        !astronomyApplicationID.isEmpty && !astronomyApplicationSecret.isEmpty
    }

    private static func configuredValue(environmentKey: String, infoKey: String) -> String {
        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey], !environmentValue.isEmpty {
            return environmentValue
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String, !infoValue.isEmpty {
            return infoValue
        }

        return ""
    }
}

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Add your database URL before connecting live auth."
        case .invalidResponse:
            return "The server response could not be read."
        case .missingToken:
            return "The server did not return a valid user session."
        }
    }
}

// Service is ready for a real backend, but falls back to local mock auth while the URL is empty.
struct AstronomyAuthService {
    func login(email: String, password: String) async throws -> UserProfile {
        if AppConfiguration.databaseURL.isEmpty {
            try await Task.sleep(for: .milliseconds(700))
            return UserProfile(id: UUID(), username: mockUsername(from: email), email: email)
        }

        return try await performAuthRequest(
            path: "/login",
            payload: ["email": email, "password": password]
        )
    }

    func signUp(username: String, email: String, password: String) async throws -> UserProfile {
        if AppConfiguration.databaseURL.isEmpty {
            try await Task.sleep(for: .milliseconds(700))
            return UserProfile(id: UUID(), username: username, email: email)
        }

        return try await performAuthRequest(
            path: "/register",
            payload: ["username": username, "email": email, "password": password]
        )
    }

    private func performAuthRequest(path: String, payload: [String: String]) async throws -> UserProfile {
        guard let url = URL(string: AppConfiguration.databaseURL + path) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AuthError.invalidResponse
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        guard let user = authResponse.user else {
            throw AuthError.missingToken
        }

        return user
    }

    private func mockUsername(from email: String) -> String {
        // A simple fallback keeps the app usable before backend wiring is added.
        email.split(separator: "@").first.map(String.init) ?? "Astronomy User"
    }
}
