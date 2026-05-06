//
//  ProfileScreen.swift
//  FinalProject
//

import SwiftUI

struct ProfileScreen: View {
    let user: UserProfile?
    @ObservedObject var viewModel: AppViewModel
    @State private var showEditProfile = false

    private var userPostCount: Int {
        guard let user else { return 0 }
        return viewModel.feedPosts.filter { $0.userID == user.id }.count
    }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 14) {
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

                        Text(viewModel.currentUser?.username ?? user?.username ?? "Astronomy User")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(AstroTheme.ink)

                        Text(viewModel.currentUser?.email ?? user?.email ?? "user@email.com")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AstroTheme.muted)
                    }
                    .padding(.top, 30)

                    HStack(spacing: 14) {
                        profileStat(title: "Posts", value: "\(userPostCount)")
                        profileStat(title: "Saved", value: "\(viewModel.savedEventCount)")
                        profileStat(title: "Trips", value: "6")
                    }

                    VStack(spacing: 14) {
                        Button {
                            showEditProfile = true
                        } label: {
                            profileRow(icon: "person.crop.circle", title: "Edit Profile")
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: EditPostsScreen(viewModel: viewModel)) {
                            profileRow(icon: "square.and.pencil", title: "Edit Posts")
                        }
                        .buttonStyle(.plain)

                        profileRow(icon: "gearshape", title: "Settings")
                        profileRow(icon: "bell", title: "Notifications")
                        profileRow(icon: "lock.shield", title: "Privacy")
                        profileRow(icon: "questionmark.circle", title: "Help & Support")
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            EditProfileScreen(user: Binding(
                get: { viewModel.currentUser },
                set: { viewModel.currentUser = $0 }
            ))
        }
    }

    private func profileStat(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .surfaceCard()
    }

    private func profileRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(AstroTheme.primary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AstroTheme.muted.opacity(0.7))
        }
        .padding(18)
        .surfaceCard()
    }
}
