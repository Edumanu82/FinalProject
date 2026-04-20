//
//  HomeScreen.swift
//  FinalProject
//
//

import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        homeHeader
                        skyHero
                        tonightSection
                        eventsSection
                        feedSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                }

                bottomNavigation
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
        }
    }

    private var homeHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Home")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Welcome, \(viewModel.currentUser?.username ?? "Explorer")")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            HStack(spacing: 12) {
                NavigationLink(destination: ProfileScreen()) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Profile")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("View account")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)

                Button("Log Out") {
                    viewModel.signOut()
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08), in: Capsule())
            }
        }
    }

    private var skyHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Tonight's Sky")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.38, green: 0.44, blue: 0.56), Color(red: 0.08, green: 0.10, blue: 0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 230)

                StarFieldOverlay()
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Clear conditions for Jupiter and Vega")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Use the sky map after sunset for the strongest visibility window.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.74))
                }
                .padding(22)
            }
        }
    }

    private var tonightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Visible Stars / Planets")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ForEach(viewModel.visibleObjects) { object in
                InfoRowCard(
                    title: object.name,
                    subtitle: object.type,
                    detail: object.timeVisible,
                    sfSymbol: object.sfSymbol
                )
            }
        }
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Upcoming Events")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ForEach(viewModel.upcomingEvents) { event in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(event.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(event.date)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.73, green: 0.83, blue: 1.0))
                    }

                    Text(event.detail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(18)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Community Feed")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ForEach(viewModel.feedPosts) { post in
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Circle()
                            .fill(Color.white.opacity(0.20))
                            .frame(width: 42, height: 42)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.85)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.username)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("2h ago")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                        }

                        Spacer()
                    }

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: post.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 180)
                        .overlay(
                            StarFieldOverlay()
                                .opacity(0.7)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        )

                    Text(post.caption)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))

                    HStack(spacing: 18) {
                        Label("\(post.likes)", systemImage: "heart.fill")
                        Label("\(post.comments)", systemImage: "message.fill")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                }
                .padding(18)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var bottomNavigation: some View {
        HStack {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(viewModel.selectedTab == tab ? .white : .white.opacity(0.48))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
