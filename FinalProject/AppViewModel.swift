//
//  AppViewModel.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import Combine
import SwiftUI

// Central view model keeps auth state and mock content in one place for this first build.
@MainActor
final class AppViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var authMode: AuthMode = .login
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var signUpUsername = ""
    @Published var signUpEmail = ""
    @Published var signUpPassword = ""
    @Published var confirmPassword = ""
    @Published var selectedTab: HomeTab = .home

    let authService = AstronomyAuthService()
    let visibleObjects = CelestialObject.sampleData
    let upcomingEvents = EventCard.sampleData
    let feedPosts = FeedPost.sampleData

    func login() async {
        errorMessage = ""

        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }

        await runAuthAction {
            currentUser = try await authService.login(email: loginEmail, password: loginPassword)
        }
    }

    func signUp() async {
        errorMessage = ""

        guard !signUpUsername.isEmpty, !signUpEmail.isEmpty, !signUpPassword.isEmpty else {
            errorMessage = "Complete every sign up field."
            return
        }

        guard signUpPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        await runAuthAction {
            currentUser = try await authService.signUp(
                username: signUpUsername,
                email: signUpEmail,
                password: signUpPassword
            )
        }
    }

    func signOut() {
        // Reset state so the app returns to the login view cleanly.
        currentUser = nil
        loginPassword = ""
        signUpPassword = ""
        confirmPassword = ""
        selectedTab = .home
        authMode = .login
    }

    private func runAuthAction(_ action: () async throws -> Void) async {
        isLoading = true

        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
