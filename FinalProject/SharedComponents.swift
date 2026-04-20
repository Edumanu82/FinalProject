//
//  SharedComponents.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import SwiftUI

// Reusable field keeps the forms visually consistent.
struct LabeledInputField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(.white.opacity(0.30)))
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.72))

            SecureField("", text: $text, prompt: Text(prompt).foregroundStyle(.white.opacity(0.30)))
                .textInputAutocapitalization(.never)
                .padding(16)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
    }
}

struct InfoRowCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let sfSymbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: sfSymbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 0.79, green: 0.87, blue: 1.0))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Text(detail)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.66))
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.10, green: 0.13, blue: 0.21), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.47, green: 0.56, blue: 0.76).opacity(0.20))
                .frame(width: 280)
                .blur(radius: 60)
                .offset(x: -120, y: -280)

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 240)
                .blur(radius: 50)
                .offset(x: 120, y: 320)
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
