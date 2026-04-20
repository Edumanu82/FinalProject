//
//  Models.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import SwiftUI

enum AuthMode: String, CaseIterable {
    case login = "Log In"
    case signUp = "Sign Up"
}

enum HomeTab: String, CaseIterable {
    case home = "Home"
    case sky = "Sky"
    case feed = "Feed"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .sky: return "sparkles"
        case .feed: return "rectangle.stack.fill"
        case .profile: return "person.fill"
        }
    }
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
}

struct CelestialObject: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let timeVisible: String
    let sfSymbol: String

    static let sampleData: [CelestialObject] = [
        .init(name: "Jupiter", type: "Planet", timeVisible: "Visible until 3:10 AM", sfSymbol: "globe.americas.fill"),
        .init(name: "Cygnus", type: "Constellation", timeVisible: "Best viewed after 9:30 PM", sfSymbol: "sparkles"),
        .init(name: "Vega", type: "Star", timeVisible: "High in the northeast", sfSymbol: "star.fill")
    ]
}

struct EventCard: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let detail: String

    static let sampleData: [EventCard] = [
        .init(title: "Meteor Shower", date: "July 12", detail: "Peak visibility after midnight with clear skies."),
        .init(title: "Saturn Rise", date: "July 18", detail: "Low eastern horizon viewing just before dawn."),
        .init(title: "Moonless Sky", date: "July 22", detail: "Best night this month for deep-sky photography.")
    ]
}

struct FeedPost: Identifiable {
    let id = UUID()
    let username: String
    let caption: String
    let likes: Int
    let comments: Int
    let gradient: [Color]

    static let sampleData: [FeedPost] = [
        .init(username: "stargazer_ana", caption: "Caught Jupiter breaking through thin clouds tonight.", likes: 128, comments: 24, gradient: [Color(red: 0.36, green: 0.45, blue: 0.62), Color(red: 0.13, green: 0.17, blue: 0.27)]),
        .init(username: "cosmic.miles", caption: "Tried a longer exposure for Cygnus and finally got a clean frame.", likes: 94, comments: 11, gradient: [Color(red: 0.48, green: 0.53, blue: 0.63), Color(red: 0.19, green: 0.22, blue: 0.33)])
    ]
}

struct AuthResponse: Codable {
    let user: UserProfile?
}
