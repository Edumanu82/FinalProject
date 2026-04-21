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
            objectSearchSection
            tonightSection
            eventsSection
            feedSection
        case .sky:
            skyHero
            objectSearchSection
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
            SectionHeader(eyebrow: "Live View", title: "Tonight's Sky", action: viewModel.skySnapshot.locationLabel)

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
                        Text(viewModel.skySnapshot.headline)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(viewModel.skySnapshot.subheadline)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.74))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            heroBadge(text: viewModel.skySnapshot.moonPhase)
                            heroBadge(text: "\(viewModel.skySnapshot.moonIllumination)% moonlight")
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                HStack(spacing: 14) {
                    statChip(title: "Sunset", value: viewModel.skyConditions.sunsetText)
                    statChip(title: "Clouds", value: viewModel.skyConditions.cloudCoverText)
                    statChip(title: "Temp", value: viewModel.skyConditions.temperatureText)
                }

                skyLocationCard
            }
        }
    }

    private var tonightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(eyebrow: "Sky Picks", title: "Visible Now", action: "\(viewModel.visibleObjects.count) objects")

            Text(viewModel.visibleObjectsStatusMessage)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(viewModel.liveVisibleObjectCount > 0 ? AstroTheme.success : AstroTheme.muted)

            ForEach(viewModel.visibleObjects) { object in
                InfoRowCard(
                    title: object.name,
                    subtitle: object.type,
                    detail: object.timeVisible,
                    sfSymbol: object.sfSymbol,
                    imageURL: object.imageURL,
                    source: object.dataSource
                )
            }
        }
    }

    private var objectSearchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(eyebrow: "Search", title: "Sky Objects", action: "Planets, stars, deep sky")

            VStack(alignment: .leading, spacing: 14) {
                TextField("Search Saturn, Orion, Milky Way...", text: $viewModel.objectSearchQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(AstroTheme.ink)
                    .tint(AstroTheme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AstroTheme.border, lineWidth: 1)
                    )

                Text(viewModel.astronomyAPIStatusMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(viewModel.remoteObjectSearchResults.isEmpty ? AstroTheme.muted : AstroTheme.success)

                if viewModel.isObjectSearchLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(AstroTheme.primary)

                        Text("Searching live astronomy catalog...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AstroTheme.muted)
                    }
                }

                ForEach(viewModel.objectSearchResults.prefix(5)) { object in
                    NavigationLink(destination: SkyObjectDetailScreen(object: object)) {
                        HStack(alignment: .top, spacing: 14) {
                            searchResultThumbnail(for: object)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(object.name)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(AstroTheme.ink)

                                    Text(object.dataSource.badgeTitle)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(object.dataSource.tint)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(object.dataSource.tint.opacity(0.14), in: Capsule())
                                }

                                Text(object.type)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AstroTheme.primary)

                                Text(object.summary)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AstroTheme.muted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AstroTheme.muted.opacity(0.7))
                        }
                        .padding(16)
                        .surfaceCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .task(id: viewModel.objectSearchQuery) {
                await viewModel.refreshObjectSearch()
            }
        }
    }

    @ViewBuilder
    private func searchResultThumbnail(for object: SearchableSkyObject) -> some View {
        if let imageURL = object.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    searchResultPlaceholder(for: object)
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            searchResultPlaceholder(for: object)
        }
    }

    private func searchResultPlaceholder(for object: SearchableSkyObject) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AstroTheme.primary.opacity(0.9), AstroTheme.secondary.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 58, height: 58)
            .overlay(
                Image(systemName: iconName(for: object.type))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            )
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

    private var skyLocationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.locationStatusMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.ink.opacity(0.78))

            VStack(alignment: .leading, spacing: 10) {
                Text("Search another sky")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AstroTheme.muted)

                HStack(spacing: 10) {
                    TextField("City or region", text: $viewModel.manualLocationQuery)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundStyle(AstroTheme.ink)
                        .tint(AstroTheme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AstroTheme.border, lineWidth: 1)
                        )

                    Button {
                        Task {
                            await viewModel.searchForLocation()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSearchingLocation {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .bold))
                            }

                            Text("Search")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [AstroTheme.primary, AstroTheme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSearchingLocation)
                }
            }

            HStack(spacing: 12) {
                compactSkyFact(title: "Visibility", value: viewModel.skyConditions.visibilityText)
                compactSkyFact(title: "Wind", value: viewModel.skyConditions.windText)
                compactSkyFact(title: "Sunrise", value: viewModel.skyConditions.sunriseText)
            }

            if viewModel.isSkyDataLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(AstroTheme.primary)

                    Text("Refreshing live sky data and NASA image previews...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }
            } else if !viewModel.skyDataErrorMessage.isEmpty {
                Text(viewModel.skyDataErrorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.70, green: 0.19, blue: 0.25))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                viewModel.requestLocationAccess()
            } label: {
                HStack {
                    Image(systemName: viewModel.activeLocationName == nil && viewModel.canRequestLocation ? "location.fill" : "location.viewfinder")
                        .font(.system(size: 15, weight: .bold))

                    Text(viewModel.locationButtonTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    Spacer()
                }
                .foregroundStyle(viewModel.canRequestLocation ? .white : AstroTheme.ink)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(locationButtonBackgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .surfaceCard()
    }

    private var locationButtonBackgroundStyle: AnyShapeStyle {
        if viewModel.activeLocationName == nil && viewModel.canRequestLocation {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AstroTheme.primary, AstroTheme.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            return AnyShapeStyle(AstroTheme.surfaceAlt)
        }
    }

    private func compactSkyFact(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.muted)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func iconName(for objectType: String) -> String {
        switch objectType.lowercased() {
        case "planet":
            return "globe.americas.fill"
        case "constellation":
            return "sparkles"
        case "star":
            return "star.fill"
        case "galaxy", "nebula", "star cluster":
            return "moon.stars.fill"
        default:
            return "sparkle"
        }
    }
}
