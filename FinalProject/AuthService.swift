//
//  AuthService.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.


import Foundation

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
    case firebaseAuthMissing
    case invalidUser
    case missingUsername

    var errorDescription: String? {
        switch self {
        case .firebaseAuthMissing:
            return "Add FirebaseAuth to the app target before using Firebase login."
        case .invalidUser:
            return "The Firebase user session could not be read."
        case .missingUsername:
            return "Choose a username before creating your account."
        }
    }
}

struct AstronomyAuthService {
    var currentUser: UserProfile? {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else { return nil }
        return makeUserProfile(from: user)
        #else
        return nil
        #endif
    }

    func login(email: String, password: String) async throws -> UserProfile {
        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return makeUserProfile(from: result.user)
        #else
        throw AuthError.firebaseAuthMissing
        #endif
    }

    func signUp(username: String, email: String, password: String) async throws -> UserProfile {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.missingUsername
        }

        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let request = result.user.createProfileChangeRequest()
        request.displayName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        try await request.commitChanges()
        try await upsertUserProfileDocument(for: result.user, username: username.trimmingCharacters(in: .whitespacesAndNewlines))

        guard let refreshedUser = Auth.auth().currentUser else {
            throw AuthError.invalidUser
        }

        return makeUserProfile(from: refreshedUser)
        #else
        throw AuthError.firebaseAuthMissing
        #endif
    }

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw AuthError.firebaseAuthMissing
        #endif
    }

    #if canImport(FirebaseAuth)
    private func makeUserProfile(from user: FirebaseAuth.User) -> UserProfile {
        let username = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUsername = (username?.isEmpty == false ? username : nil)
            ?? user.email?.split(separator: "@").first.map(String.init)
            ?? "Astronomy User"

        return UserProfile(
            id: user.uid,
            username: resolvedUsername,
            email: user.email ?? ""
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
