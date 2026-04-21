//
//  AuthScreen.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import SwiftUI

struct AuthScreen: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScreenContainer {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    authPicker
                    authCard
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [AstroTheme.primary, AstroTheme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("CosmicCircle")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AstroTheme.ink)

                    Text("Astronomy social explorer")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }
            }

            Text(viewModel.authMode == .login ? "Explore tonight's sky." : "Create your account.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)

            Text("Track visible planets, save celestial events, and join a community built around the sky above you.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 20)
    }

    private var authPicker: some View {
        HStack(spacing: 10) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.authMode = mode
                        viewModel.errorMessage = ""
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(viewModel.authMode == mode ? AstroTheme.primary : AstroTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(viewModel.authMode == mode ? AstroTheme.primary : AstroTheme.border, lineWidth: 1)
                        )
                }
                .foregroundStyle(viewModel.authMode == mode ? .white : AstroTheme.ink)
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var authCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.authMode == .login ? "Welcome back" : "Start your account")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)

            if viewModel.authMode == .login {
                Group {
                    LabeledInputField(title: "Email", text: $viewModel.loginEmail, prompt: "name@email.com", keyboardType: .emailAddress)
                    LabeledSecureField(title: "Password", text: $viewModel.loginPassword, prompt: "Enter your password")
                }
            } else {
                Group {
                    LabeledInputField(title: "Username", text: $viewModel.signUpUsername, prompt: "Choose a username")
                    LabeledInputField(title: "Email", text: $viewModel.signUpEmail, prompt: "name@email.com", keyboardType: .emailAddress)
                    LabeledSecureField(title: "Password", text: $viewModel.signUpPassword, prompt: "Create a password")
                    LabeledSecureField(title: "Confirm Password", text: $viewModel.confirmPassword, prompt: "Re-enter password")
                }
            }

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.70, green: 0.19, blue: 0.25))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                Task {
                    if viewModel.authMode == .login {
                        await viewModel.login()
                    } else {
                        await viewModel.signUp()
                    }
                }
            } label: {
                HStack {
                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.authMode == .login ? "Log In" : "Create Account")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AstroTheme.primary, AstroTheme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            Text("Authentication is connected to Firebase using the bundled project configuration.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .surfaceCard()
    }
}
