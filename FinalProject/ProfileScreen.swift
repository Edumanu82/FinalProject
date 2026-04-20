//
//  ProfileScreen.swift
//  FinalProject
//
//  Created by Carlos Fletes on 4/19/26.
//
import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 14) {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(.white)
                        )

                    Text("User")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("User@email.com")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 30)

                HStack(spacing: 14) {
                    profileStat(title: "Posts", value: "24")
                    profileStat(title: "Followers", value: "1.2K")
                    profileStat(title: "Following", value: "340")
                }

                VStack(spacing: 14) {
                    profileRow(icon: "person.crop.circle", title: "Edit Profile")
                    profileRow(icon: "gearshape", title: "Settings")
                    profileRow(icon: "bell", title: "Notifications")
                    profileRow(icon: "lock.shield", title: "Privacy")
                    profileRow(icon: "questionmark.circle", title: "Help & Support")
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.16),
                    Color(red: 0.03, green: 0.04, blue: 0.09)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func profileStat(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func profileRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
