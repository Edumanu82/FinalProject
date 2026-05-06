//
//  SharedComponents.swift
//  FinalProject
//

import SwiftUI

enum AstroTheme {
    static let primary = Color(red: 0.43, green: 0.36, blue: 0.95)
    static let secondary = Color(red: 0.19, green: 0.58, blue: 0.97)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 1.0)
    static let surface = Color.white
    static let surfaceAlt = Color(red: 0.94, green: 0.95, blue: 0.99)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.22)
    static let muted = Color(red: 0.47, green: 0.50, blue: 0.60)
    static let border = Color(red: 0.87, green: 0.89, blue: 0.96)
    static let success = Color(red: 0.14, green: 0.69, blue: 0.49)
    static let warning = Color(red: 0.99, green: 0.68, blue: 0.29)
}

struct LabeledInputField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.muted)

            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(AstroTheme.muted.opacity(0.55)))
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .padding(16)
                .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AstroTheme.border, lineWidth: 1)
                )
                .foregroundStyle(AstroTheme.ink)
        }
    }
}

struct LabeledSecureField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AstroTheme.muted)

            SecureField("", text: $text, prompt: Text(prompt).foregroundStyle(AstroTheme.muted.opacity(0.55)))
                .textInputAutocapitalization(.never)
                .padding(16)
                .background(AstroTheme.surfaceAlt, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AstroTheme.border, lineWidth: 1)
                )
                .foregroundStyle(AstroTheme.ink)
        }
    }
}

struct InfoRowCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let sfSymbol: String
    let imageURL: URL?
    let source: SkyDataSource

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AstroTheme.surfaceAlt, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)

                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                            .tint(AstroTheme.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        skyPlaceholder
                    @unknown default:
                        skyPlaceholder
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AstroTheme.warning.opacity(0.95), AstroTheme.primary.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Image(systemName: sfSymbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.28), in: Capsule())

                    Text(source.badgeTitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(source.tint.opacity(0.92), in: Capsule())
                }
                .padding(14)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AstroTheme.ink)

                    Text(detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AstroTheme.muted.opacity(0.65))
            }
        }
        .padding(16)
        .background(AstroTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AstroTheme.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 10)
    }

    private var skyPlaceholder: some View {
        LinearGradient(
            colors: [
                Color(red: 0.17, green: 0.19, blue: 0.33),
                Color(red: 0.30, green: 0.22, blue: 0.52),
                Color(red: 0.10, green: 0.12, blue: 0.21)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(StarFieldOverlay().opacity(0.8))
    }
}

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.13, blue: 0.23),
                    Color(red: 0.20, green: 0.21, blue: 0.37),
                    Color(red: 0.10, green: 0.11, blue: 0.19)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(AstroTheme.primary.opacity(0.28))
                .frame(width: 320)
                .blur(radius: 75)
                .offset(x: -130, y: -280)

            Circle()
                .fill(AstroTheme.secondary.opacity(0.22))
                .frame(width: 240)
                .blur(radius: 70)
                .offset(x: 150, y: -140)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 260)
                .blur(radius: 80)
                .offset(x: 140, y: 340)
        }
    }
}

struct StarFieldOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<22, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.7 : 0.35))
                        .frame(width: index.isMultiple(of: 4) ? 4 : 2, height: index.isMultiple(of: 4) ? 4 : 2)
                        .position(
                            x: CGFloat((index * 37) % Int(proxy.size.width)),
                            y: CGFloat((index * 53) % Int(proxy.size.height))
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ScreenContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppBackgroundView()

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(AstroTheme.canvas)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .ignoresSafeArea()

            content
        }
    }
}

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let action: String?

    init(eyebrow: String, title: String, action: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.action = action
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(AstroTheme.primary)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AstroTheme.ink)
            }

            Spacer()

            if let action {
                Text(action)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AstroTheme.muted)
            }
        }
    }
}

struct SurfaceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AstroTheme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(AstroTheme.border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 12)
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCardModifier())
    }
}
