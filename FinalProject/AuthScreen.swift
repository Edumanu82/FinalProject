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

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Astronomy")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            Text(viewModel.authMode == .login ? "Explore the night sky." : "Create your stargazing account.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Track visible planets, save celestial events, and join a community built around the sky above you.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
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
                                .fill(viewModel.authMode == mode ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(viewModel.authMode == mode ? 0.4 : 0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var authCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.authMode == .login ? "Welcome back" : "Start your account")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

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
                    .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.72))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        colors: [Color(red: 0.46, green: 0.58, blue: 0.79), Color(red: 0.20, green: 0.29, blue: 0.46)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            Text("`databaseURL` is intentionally blank right now. Auth uses a local mock session until you wire in the backend.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}
