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
            ScreenContainer {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            homeHeader
                            currentTabContent
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 24)
                    }

                    bottomNavigation
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private var homeHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CosmicCircle")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AstroTheme.ink)

                Text("Welcome, \(viewModel.currentUser?.username ?? "Explorer")")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AstroTheme.muted)
            }

            Spacer()

            HStack(spacing: 10) {
                NavigationLink(destination: ProfileScreen(user: viewModel.currentUser)) {
                    Circle()
                        .fill(AstroTheme.surface)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AstroTheme.primary)
                        )
                        .overlay(Circle().stroke(AstroTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open profile")

                Button {
                    viewModel.signOut()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AstroTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(AstroTheme.surface, in: Circle())
                        .overlay(Circle().stroke(AstroTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log out")
            }
        }
    }

    @ViewBuilder
    private var currentTabContent: some View {
        switch viewModel.selectedTab {
        case .home:
            skyHero
            tonightSection
            eventsSection
            feedSection
        case .sky:
            skyHero
            tonightSection
        case .feed:
            feedSection
        case .events:
            eventsSection
        case .profile:
            profileSummaryCard
        }
    }

    private var skyHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(eyebrow: "Live View", title: "Tonight's Sky", action: "Sky map")

            VStack(alignment: .leading, spacing: 18) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.19, blue: 0.35),
                                    Color(red: 0.28, green: 0.23, blue: 0.58),
                                    Color(red: 0.09, green: 0.11, blue: 0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 230)

                    StarFieldOverlay()
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.95, green: 0.76, blue: 0.49), Color(red: 0.66, green: 0.39, blue: 0.18)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 66
                            )
                        )
                        .frame(width: 118, height: 118)
                        .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 3))
                        .padding(22)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Clear conditions for Jupiter and Vega")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Use the sky map after sunset for the strongest visibility window.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.74))

                        HStack(spacing: 10) {
                            heroBadge(text: "Sky map")
                            heroBadge(text: "94% visible")
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                HStack(spacing: 14) {
                    statChip(title: "Sunset", value: "7:44 PM")
                    statChip(title: "Clouds", value: "Low")
                    statChip(title: "Moon", value: "12%")
                }
            }
        }
    }

    private var tonightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(eyebrow: "Planets", title: "Visible Now", action: "3 objects")

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
            SectionHeader(eyebrow: "Events", title: "Upcoming Events", action: "This month")

            ForEach(viewModel.upcomingEvents) { event in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(event.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AstroTheme.ink)

                        Spacer()

                        Text(event.date)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AstroTheme.primary)
                    }

                    Text(event.detail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }
                .padding(18)
                .surfaceCard()
            }
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(eyebrow: "Community", title: "Astro Feed", action: "Latest")

            ForEach(viewModel.feedPosts) { post in
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Circle()
                            .fill(AstroTheme.surfaceAlt)
                            .frame(width: 42, height: 42)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(AstroTheme.primary))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.username)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AstroTheme.ink)

                            Text("2h ago")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(AstroTheme.muted)
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
                        .foregroundStyle(AstroTheme.ink.opacity(0.78))

                    HStack(spacing: 18) {
                        Label("\(post.likes)", systemImage: "heart.fill")
                        Label("\(post.comments)", systemImage: "message.fill")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AstroTheme.muted)
                }
                .padding(18)
                .surfaceCard()
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
                    .foregroundStyle(viewModel.selectedTab == tab ? AstroTheme.primary : AstroTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if viewModel.selectedTab == tab {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AstroTheme.primary.opacity(0.12))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(AstroTheme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(AstroTheme.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 12)
    }

    private var profileSummaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(eyebrow: "Account", title: "Profile & Settings")

            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AstroTheme.primary, AstroTheme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 28, weight: .bold)).foregroundStyle(.white))

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentUser?.username ?? "Explorer")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AstroTheme.ink)

                    Text(viewModel.currentUser?.email ?? "explorer@email.com")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }

                Spacer()
            }

            NavigationLink(destination: ProfileScreen(user: viewModel.currentUser)) {
                Text("Open profile")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [AstroTheme.primary, AstroTheme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .surfaceCard()
    }

    private func heroBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.14), in: Capsule())
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.muted)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .surfaceCard()
    }
}

