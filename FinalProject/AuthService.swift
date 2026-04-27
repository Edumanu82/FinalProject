//
//  AuthService.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

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
    case invalidResponse
    case missingUser

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server response could not be read."
        case .missingUser:
            return "No authenticated user was found."
        }
    }
}

struct AstronomyAuthService {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    func login(email: String, password: String) async throws -> UserProfile {
        let result = try await auth.signIn(withEmail: email, password: password)
        let uid = result.user.uid

        let snapshot = try await db.collection("users").document(uid).getDocument()

        guard let data = snapshot.data() else {
            throw AuthError.missingUser
        }

        let username = data["username"] as? String
            ?? email.split(separator: "@").first.map(String.init)
            ?? "Astronomy User"

        let storedEmail = data["email"] as? String ?? email

        return UserProfile(
            id: uid,
            username: username,
            email: storedEmail
        )
    }

    func signUp(username: String, email: String, password: String) async throws -> UserProfile {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let userData: [String: Any] = [
            "userID": uid,
            "username": username,
            "email": email,
            "updatedAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(userData)

        return UserProfile(
            id: uid,
            username: username,
            email: email
        )
    }

    private func upsertUserProfileDocument(for user: FirebaseAuth.User, username: String) async throws {
        #if canImport(FirebaseFirestore)
        try await FirebaseFirestore.Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData([
                "userID": user.uid,
                "username": username,
                "email": user.email ?? "",
                "updatedAt": FirebaseFirestore.Timestamp(date: Date())
            ], merge: true)
        #endif
    }
    #endif
}
