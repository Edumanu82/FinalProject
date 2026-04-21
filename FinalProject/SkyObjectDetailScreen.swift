//
//  SkyObjectDetailScreen.swift
//  FinalProject
//
//

import SwiftUI

struct SkyObjectDetailScreen: View {
    let object: SearchableSkyObject

    var body: some View {
        ScreenContainer {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroImage

                    VStack(alignment: .leading, spacing: 14) {
                        badgeRow

                        Text(object.name)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AstroTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(object.summary)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AstroTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        scrollHint
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 16) {
                        detailCard(title: "What You'll Notice Outside", body: outdoorViewingNote)
                        detailCard(title: "Visibility Tip", body: object.visibilityTip)
                        detailCard(title: "What To Search For", body: object.tags.joined(separator: ", "))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(object.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = object.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        detailPlaceholder
                    case .failure:
                        detailPlaceholder
                    @unknown default:
                        detailPlaceholder
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                detailPlaceholder
            }

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.68)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(object.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(outdoorViewingNote)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 24)
    }

    private var badgeRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                typeBadge
                sourceBadge
            }

            VStack(alignment: .leading, spacing: 8) {
                typeBadge
                sourceBadge
            }
        }
    }

    private var typeBadge: some View {
        Text(object.type.uppercased())
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(AstroTheme.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var sourceBadge: some View {
        Text(object.dataSource.statusTitle)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(object.dataSource.tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(object.dataSource.tint.opacity(0.14), in: Capsule())
    }

    private var detailPlaceholder: some View {
        LinearGradient(
            colors: [
                Color(red: 0.17, green: 0.19, blue: 0.33),
                Color(red: 0.30, green: 0.22, blue: 0.52),
                Color(red: 0.10, green: 0.12, blue: 0.21)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(StarFieldOverlay().opacity(0.9))
        .overlay(
            Image(systemName: detailIconName)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
        )
    }

    private var outdoorViewingNote: String {
        if object.tags.contains(where: { $0.localizedCaseInsensitiveContains("dark") }) {
            return "This target looks best once you're outside city lights with a darker horizon."
        }

        if object.type.localizedCaseInsensitiveContains("planet") {
            return "A steady outdoor view and a clear horizon will make this object easier to track with your eyes or binoculars."
        }

        if object.type.localizedCaseInsensitiveContains("constellation") {
            return "Step outside, give your eyes a few minutes to adapt, and trace the brighter anchor stars first."
        }

        return "The clearest outdoor view comes after your eyes adjust and the horizon is free of haze or bright local lights."
    }

    private var scrollHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 12, weight: .bold))
            Text(object.imageURL == nil ? "Image preview will appear when a strong catalog match is found." : "Image preview matched from the astronomy image catalog.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(AstroTheme.muted)
    }

    private var detailIconName: String {
        switch object.type.lowercased() {
        case "planet":
            return "globe.americas.fill"
        case "constellation":
            return "sparkles"
        case "star", "star cluster":
            return "star.fill"
        default:
            return "moon.stars.fill"
        }
    }

    private func detailCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.ink)

            Text(body)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AstroTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .surfaceCard()
    }
}
