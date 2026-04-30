//
//  EditProfileScreen.swift
//  FinalProject
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileScreen: View {
    @Binding var user: UserProfile?

    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AstroTheme.primary, AstroTheme.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 42))
                                    .foregroundStyle(.white)
                            )

                        Text("Edit Profile")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        TextField("Enter username", text: $username)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(user?.email ?? "No email")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(
                        LinearGradient(
                            colors: [AstroTheme.primary, AstroTheme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(isSaving)

                    Spacer()
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                username = user?.username ?? ""
            }
        }
    }

    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "No logged in user found."
            return
        }

        guard let currentUser = user else {
            errorMessage = "No user found"
            return
        }

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username cannot be empty"
            return
        }

        isSaving = true
        errorMessage = nil

        Firestore.firestore().collection("users").document(uid).updateData([
            "username": trimmedUsername,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            isSaving = false

            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                user = UserProfile(
                    id: uid,
                    username: trimmedUsername,
                    email: currentUser.email
                )
                dismiss()
            }
        }
    }
}
