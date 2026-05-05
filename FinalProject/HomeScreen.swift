//
//  HomeScreen.swift
//  FinalProject
//
//

import PhotosUI
import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isShowingCreatePostSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var newPostCaption = ""
    @State private var createPostErrorMessage = ""
    @State private var isSubmittingPost = false
    @State private var activeCommentsPost: FeedPost?
    @State private var newCommentText = ""
    @State private var isSubmittingComment = false

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
                NavigationLink(destination: ProfileScreen(user: viewModel.currentUser, viewModel: viewModel))  {
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
            SectionHeader(eyebrow: "Events", title: "Upcoming Events", action: "\(viewModel.savedEventCount) saved")

            ForEach(viewModel.upcomingEvents) { event in
                HStack(alignment: .top, spacing: 12) {
                    NavigationLink(destination: EventDetailScreen(event: event, viewModel: viewModel)) {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AstroTheme.primary.opacity(0.92), AstroTheme.secondary.opacity(0.86)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Image(systemName: event.sfSymbol)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 7) {
                                HStack(spacing: 8) {
                                    Text(event.category.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(AstroTheme.primary)

                                    Text(event.date)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(AstroTheme.muted)
                                }

                                Text(event.title)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(AstroTheme.ink)

                                Text(event.detail)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(AstroTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)

                                Label(event.bestTime, systemImage: "clock.fill")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AstroTheme.ink.opacity(0.72))
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AstroTheme.muted.opacity(0.7))
                                .padding(.top, 4)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.toggleSavedEvent(event)
                    } label: {
                        Image(systemName: viewModel.isEventSaved(event) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(viewModel.isEventSaved(event) ? AstroTheme.primary : AstroTheme.muted)
                            .frame(width: 38, height: 38)
                            .background(AstroTheme.surfaceAlt, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.isEventSaved(event) ? "Unsave event" : "Save event")
                }
                .padding(18)
                .surfaceCard()
            }
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(eyebrow: "Community", title: "Astro Feed", action: "Latest")

            Button {
                isShowingCreatePostSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))

                    Text("Create Post")
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AstroTheme.primary, AstroTheme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            if viewModel.isFeedLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(AstroTheme.primary)

                    Text("Loading the latest posts from Firebase...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }
            } else if !viewModel.feedErrorMessage.isEmpty {
                Text(viewModel.feedErrorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.70, green: 0.19, blue: 0.25))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

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

                            Text(post.timestampText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(AstroTheme.muted)
                        }

                        Spacer()
                        
                        if viewModel.currentUser?.id == post.userID {
                            Menu {
                                Button(role: .destructive) {
                                    Task {
                                        _ = await viewModel.deletePost(withID: post.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AstroTheme.muted)
                                    .padding(8)
                            }
                            .accessibilityLabel("Post options")
                        }
                    }

                    feedPostMedia(for: post)

                    Text(post.caption)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.ink.opacity(0.78))

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                _ = await viewModel.toggleLike(for: post)
                            }
                        } label: {
                            Label("\(post.likes)", systemImage: post.isLiked(by: viewModel.currentUser?.id) ? "heart.fill" : "heart")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    post.isLiked(by: viewModel.currentUser?.id) ? AstroTheme.primary.opacity(0.12) : AstroTheme.surfaceAlt,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.pendingLikePostIDs.contains(post.id))
                        .foregroundStyle(post.isLiked(by: viewModel.currentUser?.id) ? AstroTheme.primary : AstroTheme.muted)
                        .accessibilityLabel(post.isLiked(by: viewModel.currentUser?.id) ? "Unlike post" : "Like post")

                        Button {
                            openComments(for: post)
                        } label: {
                            Label("\(post.comments)", systemImage: "message.fill")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AstroTheme.surfaceAlt, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AstroTheme.muted)
                        .accessibilityLabel("Open comments")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .padding(18)
                .surfaceCard()
            }
        }
        .sheet(isPresented: $isShowingCreatePostSheet, onDismiss: resetCreatePostDraft) {
            CreatePostSheet(
                selectedPhotoItem: $selectedPhotoItem,
                selectedPhotoData: $selectedPhotoData,
                caption: $newPostCaption,
                errorMessage: $createPostErrorMessage,
                isSubmittingPost: $isSubmittingPost,
                onCreatePost: submitNewPost
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $activeCommentsPost, onDismiss: closeComments) { post in
            CommentsSheet(
                post: post,
                viewModel: viewModel,
                commentText: $newCommentText,
                isSubmittingComment: $isSubmittingComment,
                onSubmit: { submitComment(for: post) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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

            NavigationLink(destination: ProfileScreen(user: viewModel.currentUser, viewModel: viewModel)) {
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

    
    @ViewBuilder
    private func feedPostMedia(for post: FeedPost) -> some View {
        if let imageData = post.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            postGradientPlaceholder(for: post)
        }
    }

    private func submitNewPost() {
        guard selectedPhotoData != nil else {
            createPostErrorMessage = "Choose a photo to post."
            return
        }

        let trimmedCaption = newPostCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCaption.isEmpty else {
            createPostErrorMessage = "Add a description for your post."
            return
        }

        isSubmittingPost = true

        Task {
            let errorMessage = await viewModel.createPost(
                caption: trimmedCaption,
                imageData: selectedPhotoData
            )
            await MainActor.run {
                isSubmittingPost = false

                if let errorMessage {
                    createPostErrorMessage = errorMessage
                } else {
                    isShowingCreatePostSheet = false
                    resetCreatePostDraft()
                }
            }
        }
    }

    private func resetCreatePostDraft() {
        selectedPhotoItem = nil
        selectedPhotoData = nil
        newPostCaption = ""
        createPostErrorMessage = ""
        isSubmittingPost = false
    }

    private func openComments(for post: FeedPost) {
        newCommentText = ""
        activeCommentsPost = post
        viewModel.startCommentsListener(for: post.id)
    }

    private func closeComments() {
        viewModel.stopCommentsListener()
        newCommentText = ""
        isSubmittingComment = false
    }

    private func submitComment(for post: FeedPost) {
        let trimmedComment = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedComment.isEmpty else {
            viewModel.commentsErrorMessage = "Write a comment first."
            return
        }

        isSubmittingComment = true

        Task {
            let errorMessage = await viewModel.addComment(to: post.id, text: trimmedComment)

            await MainActor.run {
                isSubmittingComment = false

                if let errorMessage {
                    viewModel.commentsErrorMessage = errorMessage
                } else {
                    newCommentText = ""
                }
            }
        }
    }

    private func postGradientPlaceholder(for post: FeedPost) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: post.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 180)
            .overlay(
                StarFieldOverlay()
                    .opacity(0.7)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
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

private struct CreatePostSheet: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedPhotoData: Data?
    @Binding var caption: String
    @Binding var errorMessage: String
    @Binding var isSubmittingPost: Bool

    let onCreatePost: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Share a fresh sky capture with the astro feed.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [AstroTheme.primary.opacity(0.92), AstroTheme.secondary.opacity(0.82)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 220)
                                .overlay(
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 30, weight: .bold))
                                        Text("Upload a photo")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                        Text("Pick an image from your library")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.78))
                                    }
                                    .foregroundStyle(.white)
                                )
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AstroTheme.muted)

                        TextEditor(text: $caption)
                            .frame(minHeight: 130)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AstroTheme.border, lineWidth: 1)
                            )
                            .foregroundStyle(AstroTheme.ink)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.70, green: 0.19, blue: 0.25))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(action: onCreatePost) {
                        Group {
                            if isSubmittingPost {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                            } else {
                                Text("Post to Feed")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [AstroTheme.primary, AstroTheme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmittingPost)
                }
                .padding(20)
            }
            .background(AstroTheme.canvas)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }

            do {
                selectedPhotoData = try await selectedPhotoItem.loadTransferable(type: Data.self)
                errorMessage = ""
            } catch {
                selectedPhotoData = nil
                errorMessage = "The selected photo could not be loaded."
            }
        }
    }
}

private struct EventDetailScreen: View {
    let event: EventCard
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScreenContainer {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    eventHero
                    quickFacts
                    eventDetailCard(
                        title: "Viewing Tip",
                        icon: "eye.fill",
                        text: event.viewingTip
                    )
                    eventDetailCard(
                        title: "Equipment",
                        icon: "camera.aperture",
                        text: event.equipment
                    )
                    eventDetailCard(
                        title: "Location",
                        icon: "location.fill",
                        text: event.locationNote
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var eventHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.18, blue: 0.34),
                            AstroTheme.primary.opacity(0.92),
                            Color(red: 0.08, green: 0.11, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 230)

            StarFieldOverlay()
                .opacity(0.8)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Label(event.category, systemImage: event.sfSymbol)
                    Text(event.date)
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15), in: Capsule())

                Text(event.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(event.detail)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    viewModel.toggleSavedEvent(event)
                } label: {
                    Label(viewModel.isEventSaved(event) ? "Saved" : "Save Event", systemImage: viewModel.isEventSaved(event) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AstroTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(22)
        }
    }

    private var quickFacts: some View {
        HStack(spacing: 12) {
            detailFact(title: "Best Time", value: event.bestTime, icon: "clock.fill")
            detailFact(title: "Date", value: event.date, icon: "calendar")
        }
    }

    private func detailFact(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AstroTheme.primary)

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.muted)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .surfaceCard()
    }

    private func eventDetailCard(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.primary)

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .surfaceCard()
    }
}

private struct CommentsSheet: View {
    let post: FeedPost
    @ObservedObject var viewModel: AppViewModel
    @Binding var commentText: String
    @Binding var isSubmittingComment: Bool

    let onSubmit: () -> Void

    private var canSubmitComment: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmittingComment
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        postPreview

                        if viewModel.isCommentsLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(AstroTheme.primary)

                                Text("Loading comments...")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AstroTheme.muted)
                            }
                            .padding(.vertical, 8)
                        } else if viewModel.activePostComments.isEmpty {
                            Text("No comments yet.")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(AstroTheme.muted)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 28)
                        }

                        ForEach(viewModel.activePostComments) { comment in
                            commentRow(comment)
                        }

                        if !viewModel.commentsErrorMessage.isEmpty {
                            Text(viewModel.commentsErrorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(red: 0.70, green: 0.19, blue: 0.25))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(20)
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("", text: $commentText, prompt: Text("Add a comment...").foregroundStyle(AstroTheme.muted.opacity(0.65)))
                        .submitLabel(.send)
                        .onSubmit {
                            if canSubmitComment {
                                onSubmit()
                            }
                        }
                        .foregroundStyle(AstroTheme.ink)
                        .tint(AstroTheme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AstroTheme.border, lineWidth: 1)
                        )

                    Button(action: onSubmit) {
                        Group {
                            if isSubmittingComment {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(
                            LinearGradient(
                                colors: [AstroTheme.primary, AstroTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .opacity(canSubmitComment ? 1 : 0.45)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmitComment)
                    .accessibilityLabel("Send comment")
                }
                .padding(16)
                .background(AstroTheme.surface)
            }
            .background(AstroTheme.canvas)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var postPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AstroTheme.surfaceAlt)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(AstroTheme.primary))

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AstroTheme.ink)

                    Text(post.timestampText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }
            }

            Text(post.caption)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.ink.opacity(0.78))
                .lineLimit(3)
        }
        .padding(16)
        .background(AstroTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AstroTheme.border, lineWidth: 1))
    }

    private func commentRow(_ comment: PostComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AstroTheme.primary.opacity(0.12))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "person.fill").foregroundStyle(AstroTheme.primary))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AstroTheme.ink)

                    Text(comment.timestampText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                }

                Text(comment.text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AstroTheme.ink.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AstroTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AstroTheme.border, lineWidth: 1))
    }
}
