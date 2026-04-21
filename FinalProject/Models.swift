//
//  Models.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import CoreLocation
import SwiftUI

enum AuthMode: String, CaseIterable {
    case login = "Log In"
    case signUp = "Sign Up"
}

enum HomeTab: String, CaseIterable {
    case home = "Home"
    case sky = "Sky"
    case feed = "Feed"
    case events = "Events"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .sky: return "sparkles"
        case .feed: return "square.grid.2x2.fill"
        case .events: return "calendar"
        case .profile: return "gearshape.fill"
        }
    }
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
}

enum SkyDataSource {
    case live
    case fallback

    var badgeTitle: String {
        switch self {
        case .live:
            return "Live"
        case .fallback:
            return "Guide"
        }
    }

    var statusTitle: String {
        switch self {
        case .live:
            return "Live AstronomyAPI"
        case .fallback:
            return "Fallback Guide"
        }
    }

    var tint: Color {
        switch self {
        case .live:
            return AstroTheme.success
        case .fallback:
            return AstroTheme.warning
        }
    }
}

struct CelestialObject: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let timeVisible: String
    let sfSymbol: String
    var imageURL: URL?
    var dataSource: SkyDataSource = .fallback

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

struct SearchableSkyObject: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let summary: String
    let visibilityTip: String
    let tags: [String]
    var imageURL: URL?
    var dataSource: SkyDataSource = .fallback

    static let catalog: [SearchableSkyObject] = [
        .init(name: "Saturn", type: "Planet", summary: "The ringed gas giant is one of the easiest telescopic showpieces in the night sky.", visibilityTip: "Best when it rises well above the horizon and the air is steady.", tags: ["planet", "rings", "solar system"]),
        .init(name: "Jupiter", type: "Planet", summary: "The largest planet in the solar system, bright enough to spot even under moderate light pollution.", visibilityTip: "Look for a bright, non-twinkling object and check it when it is high in the sky.", tags: ["planet", "solar system", "gas giant"]),
        .init(name: "Mars", type: "Planet", summary: "A reddish world that becomes especially striking during favorable oppositions.", visibilityTip: "It is easiest to spot when it glows with a steady orange-red color.", tags: ["planet", "red planet", "solar system"]),
        .init(name: "Venus", type: "Planet", summary: "The brightest planet, often visible as a brilliant evening or morning star.", visibilityTip: "Best seen shortly after sunset or before sunrise depending on the season.", tags: ["planet", "evening star", "morning star"]),
        .init(name: "Orion", type: "Constellation", summary: "One of the most recognizable constellations, marked by Orion’s Belt.", visibilityTip: "Winter evenings in the northern hemisphere are ideal.", tags: ["constellation", "belt", "nebula"]),
        .init(name: "Cygnus", type: "Constellation", summary: "The Swan stretches through the Milky Way and contains rich star fields.", visibilityTip: "Late summer and early autumn make it especially prominent.", tags: ["constellation", "swan", "milky way"]),
        .init(name: "Scorpius", type: "Constellation", summary: "A dramatic southern constellation with a bright red heart, Antares.", visibilityTip: "Best from lower latitudes during summer evenings.", tags: ["constellation", "antares", "southern sky"]),
        .init(name: "Milky Way", type: "Galaxy", summary: "The glowing band of our home galaxy, best appreciated from dark skies.", visibilityTip: "Find a moonless night far from city lights for the strongest view.", tags: ["galaxy", "dark sky", "deep sky"]),
        .init(name: "Andromeda Galaxy", type: "Galaxy", summary: "The nearest major galaxy to the Milky Way and visible with the naked eye from dark locations.", visibilityTip: "Autumn nights with low moonlight give the best chance to see it.", tags: ["galaxy", "m31", "deep sky"]),
        .init(name: "Pleiades", type: "Star Cluster", summary: "A compact open cluster that looks like a tiny dipper of bright blue-white stars.", visibilityTip: "Easy to spot in cooler-season skies, especially with binoculars.", tags: ["cluster", "seven sisters", "binoculars"]),
        .init(name: "Vega", type: "Star", summary: "A bright blue-white star that anchors the Summer Triangle.", visibilityTip: "Very easy to find high overhead on summer nights.", tags: ["star", "summer triangle", "lyra"]),
        .init(name: "Sirius", type: "Star", summary: "The brightest star in Earth’s night sky, shimmering low in winter skies.", visibilityTip: "Best once it climbs above the horizon and stops flashing through turbulence.", tags: ["star", "dog star", "winter"]),
        .init(name: "Carina Nebula", type: "Nebula", summary: "A vast southern nebula filled with bright gas, dust, and young stars.", visibilityTip: "Most rewarding from southern latitudes and dark skies.", tags: ["nebula", "southern sky", "deep sky"]),
        .init(name: "Lagoon Nebula", type: "Nebula", summary: "A bright emission nebula in Sagittarius that responds well to binoculars and telescopes.", visibilityTip: "Summer dark-sky nights are ideal.", tags: ["nebula", "messier", "summer"]),
        .init(name: "Antares", type: "Star", summary: "A red supergiant that marks the heart of Scorpius.", visibilityTip: "Best from low-latitude or southern observers in warmer months.", tags: ["star", "scorpius", "red supergiant"])
    ]
}

struct SkySnapshot {
    let locationLabel: String
    let headline: String
    let subheadline: String
    let bestWindow: String
    let moonPhase: String
    let moonIllumination: Int
    let latitudeLabel: String
    let visibleObjects: [CelestialObject]

    static let placeholder = SkySnapshot(
        locationLabel: "Sky guide",
        headline: "Astronomy picks for tonight",
        subheadline: "Allow location to tailor visibility advice to your hemisphere and observing season.",
        bestWindow: "9:00 PM - 11:30 PM",
        moonPhase: "Waxing Crescent",
        moonIllumination: 24,
        latitudeLabel: "Location unavailable",
        visibleObjects: CelestialObject.sampleData
    )
}

struct SkyConditions {
    let temperatureText: String
    let cloudCoverText: String
    let windText: String
    let visibilityText: String
    let sunriseText: String
    let sunsetText: String

    static let fallback = SkyConditions(
        temperatureText: "--",
        cloudCoverText: "--",
        windText: "--",
        visibilityText: "Live weather unavailable",
        sunriseText: "--",
        sunsetText: "--"
    )
}

enum SkyInsightEngine {
    static func snapshot(for date: Date, coordinate: CLLocationCoordinate2D?) -> SkySnapshot {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let latitude = coordinate?.latitude ?? 34.05
        let longitude = coordinate?.longitude ?? -118.24
        let hemisphere = latitude >= 0 ? "northern" : "southern"
        let season = seasonName(for: month, inNorthernHemisphere: latitude >= 0)
        let moonFraction = moonPhaseFraction(for: date)
        let illumination = Int((0.5 * (1 - cos(2 * .pi * moonFraction)) * 100).rounded())
        let moonPhase = moonPhaseName(for: moonFraction)
        let sunsetHour = approximateSunsetHour(dayOfYear: calendar.ordinality(of: .day, in: .year, for: date) ?? 1, latitude: latitude)
        let observingStart = formattedHour(sunsetHour + 1.0)
        let observingEnd = formattedHour(min(sunsetHour + 4.0, 23.75))
        let visibleObjects = recommendedObjects(
            month: month,
            latitude: latitude,
            hemisphere: hemisphere,
            moonIllumination: illumination
        )

        return SkySnapshot(
            locationLabel: coordinate == nil ? "Using a default sky guide" : "Personalized for your location",
            headline: headline(for: season, hemisphere: hemisphere, moonIllumination: illumination),
            subheadline: "Best results for \(season.lowercased()) skies in the \(hemisphere) hemisphere near \(formattedCoordinate(latitude, longitude)).",
            bestWindow: "\(observingStart) - \(observingEnd)",
            moonPhase: moonPhase,
            moonIllumination: illumination,
            latitudeLabel: formattedCoordinate(latitude, longitude),
            visibleObjects: visibleObjects
        )
    }

    private static func recommendedObjects(month: Int, latitude: Double, hemisphere: String, moonIllumination: Int) -> [CelestialObject] {
        let darkSkyNote = moonIllumination < 35 ? "Dark-sky window is favorable tonight." : "Bright moonlight may soften faint details."
        let absLatitude = abs(latitude)

        switch (hemisphere, month) {
        case ("northern", 3...5):
            if absLatitude < 24 {
                return [
                    CelestialObject(name: "Jupiter", type: "Planet", timeVisible: "Bright in the evening sky from lower latitudes", sfSymbol: "globe.americas.fill"),
                    CelestialObject(name: "Leo", type: "Constellation", timeVisible: "High after 9:00 PM", sfSymbol: "sparkles"),
                    CelestialObject(name: "Regulus", type: "Star", timeVisible: darkSkyNote, sfSymbol: "star.fill")
                ]
            }
            return [
                CelestialObject(name: "Leo", type: "Constellation", timeVisible: "Best after 9:00 PM", sfSymbol: "sparkles"),
                CelestialObject(name: "Arcturus", type: "Star", timeVisible: "High in the east by late evening", sfSymbol: "star.fill"),
                CelestialObject(name: "Jupiter", type: "Planet", timeVisible: darkSkyNote, sfSymbol: "globe.americas.fill")
            ]
        case ("northern", 6...8):
            if absLatitude > 45 {
                return [
                    CelestialObject(name: "Deneb", type: "Star", timeVisible: "Very strong from higher northern latitudes", sfSymbol: "star.fill"),
                    CelestialObject(name: "Cygnus", type: "Constellation", timeVisible: "Nearly overhead on clear nights", sfSymbol: "sparkles"),
                    CelestialObject(name: "Milky Way Core", type: "Deep Sky", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
                ]
            } else if absLatitude < 24 {
                return [
                    CelestialObject(name: "Scorpius", type: "Constellation", timeVisible: "Higher above the southern horizon", sfSymbol: "sparkles"),
                    CelestialObject(name: "Antares", type: "Star", timeVisible: "Bright and easier to spot from lower latitudes", sfSymbol: "star.fill"),
                    CelestialObject(name: "Milky Way Core", type: "Deep Sky", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
                ]
            }
            return [
                CelestialObject(name: "Vega", type: "Star", timeVisible: "Very high after sunset", sfSymbol: "star.fill"),
                CelestialObject(name: "Cygnus", type: "Constellation", timeVisible: "Strong overhead visibility by late evening", sfSymbol: "sparkles"),
                CelestialObject(name: "Milky Way Core", type: "Deep Sky", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
            ]
        case ("northern", 9...11):
            if absLatitude < 24 {
                return [
                    CelestialObject(name: "Saturn", type: "Planet", timeVisible: "Rises well for lower-latitude viewing", sfSymbol: "globe.americas.fill"),
                    CelestialObject(name: "Fomalhaut", type: "Star", timeVisible: "Clearer from southern-facing horizons", sfSymbol: "star.fill"),
                    CelestialObject(name: "Pegasus", type: "Constellation", timeVisible: darkSkyNote, sfSymbol: "sparkles")
                ]
            }
            return [
                CelestialObject(name: "Andromeda Galaxy", type: "Galaxy", timeVisible: "Best from 9:30 PM onward", sfSymbol: "moon.stars.fill"),
                CelestialObject(name: "Pegasus", type: "Constellation", timeVisible: "High in the southeast after dusk", sfSymbol: "sparkles"),
                CelestialObject(name: "Saturn", type: "Planet", timeVisible: darkSkyNote, sfSymbol: "globe.americas.fill")
            ]
        case ("northern", _):
            if absLatitude > 45 {
                return [
                    CelestialObject(name: "Auriga", type: "Constellation", timeVisible: "High in colder northern skies", sfSymbol: "sparkles"),
                    CelestialObject(name: "Capella", type: "Star", timeVisible: "Bright overhead target", sfSymbol: "star.fill"),
                    CelestialObject(name: "Orion", type: "Constellation", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
                ]
            }
            return [
                CelestialObject(name: "Orion", type: "Constellation", timeVisible: "Dominant in the evening sky", sfSymbol: "sparkles"),
                CelestialObject(name: "Sirius", type: "Star", timeVisible: "Brilliant in the southeast after dusk", sfSymbol: "star.fill"),
                CelestialObject(name: "Taurus", type: "Constellation", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
            ]
        case ("southern", 3...5):
            if absLatitude > 35 {
                return [
                    CelestialObject(name: "Crux", type: "Constellation", timeVisible: "Excellent from southern latitudes", sfSymbol: "sparkles"),
                    CelestialObject(name: "Alpha Centauri", type: "Star", timeVisible: "Very bright in mid-evening", sfSymbol: "star.fill"),
                    CelestialObject(name: "Carina Nebula", type: "Nebula", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
                ]
            }
            return [
                CelestialObject(name: "Crux", type: "Constellation", timeVisible: "High in the south after dark", sfSymbol: "sparkles"),
                CelestialObject(name: "Alpha Centauri", type: "Star", timeVisible: "Very bright in mid-evening", sfSymbol: "star.fill"),
                CelestialObject(name: "Carina Nebula", type: "Nebula", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
            ]
        case ("southern", 6...8):
            if absLatitude < 20 {
                return [
                    CelestialObject(name: "Scorpius", type: "Constellation", timeVisible: "Wide and high from subtropical skies", sfSymbol: "sparkles"),
                    CelestialObject(name: "Sagittarius", type: "Constellation", timeVisible: "Dense star clouds after dusk", sfSymbol: "moon.stars.fill"),
                    CelestialObject(name: "Antares", type: "Star", timeVisible: darkSkyNote, sfSymbol: "star.fill")
                ]
            }
            return [
                CelestialObject(name: "Scorpius", type: "Constellation", timeVisible: "Best by late evening", sfSymbol: "sparkles"),
                CelestialObject(name: "Sagittarius", type: "Constellation", timeVisible: "Rich star fields after dusk", sfSymbol: "moon.stars.fill"),
                CelestialObject(name: "Antares", type: "Star", timeVisible: darkSkyNote, sfSymbol: "star.fill")
            ]
        case ("southern", 9...11):
            if absLatitude > 35 {
                return [
                    CelestialObject(name: "Large Magellanic Cloud", type: "Galaxy", timeVisible: "Excellent from far-southern skies", sfSymbol: "moon.stars.fill"),
                    CelestialObject(name: "Tucana", type: "Constellation", timeVisible: "Best later in the evening", sfSymbol: "sparkles"),
                    CelestialObject(name: "Fomalhaut", type: "Star", timeVisible: darkSkyNote, sfSymbol: "star.fill")
                ]
            }
            return [
                CelestialObject(name: "Large Magellanic Cloud", type: "Galaxy", timeVisible: "Clearer after 10:00 PM", sfSymbol: "moon.stars.fill"),
                CelestialObject(name: "Fomalhaut", type: "Star", timeVisible: "Visible low in the south-west", sfSymbol: "star.fill"),
                CelestialObject(name: "Saturn", type: "Planet", timeVisible: darkSkyNote, sfSymbol: "globe.americas.fill")
            ]
        default:
            return [
                CelestialObject(name: "Orion", type: "Constellation", timeVisible: "High overhead during evening hours", sfSymbol: "sparkles"),
                CelestialObject(name: "Canopus", type: "Star", timeVisible: "Bright southern target after dusk", sfSymbol: "star.fill"),
                CelestialObject(name: "Tarantula Nebula", type: "Nebula", timeVisible: darkSkyNote, sfSymbol: "moon.stars.fill")
            ]
        }
    }

    private static func headline(for season: String, hemisphere: String, moonIllumination: Int) -> String {
        if moonIllumination < 35 {
            return "Dark skies look promising for \(season.lowercased()) observing"
        } else if moonIllumination > 75 {
            return "Bright moonlight will shape tonight's \(season.lowercased()) viewing"
        } else {
            return "Strong \(season.lowercased()) targets are lining up tonight"
        }
    }

    private static func seasonName(for month: Int, inNorthernHemisphere: Bool) -> String {
        switch month {
        case 3...5:
            return inNorthernHemisphere ? "Spring" : "Autumn"
        case 6...8:
            return inNorthernHemisphere ? "Summer" : "Winter"
        case 9...11:
            return inNorthernHemisphere ? "Autumn" : "Spring"
        default:
            return inNorthernHemisphere ? "Winter" : "Summer"
        }
    }

    private static func approximateSunsetHour(dayOfYear: Int, latitude: Double) -> Double {
        let latitudeRadians = latitude * .pi / 180
        let declination = -23.44 * cos((2 * .pi / 365) * Double(dayOfYear + 10))
        let declinationRadians = declination * .pi / 180
        let argument = max(-1.0, min(1.0, -tan(latitudeRadians) * tan(declinationRadians)))
        let hourAngle = acos(argument)
        let daylightHours = 24 * hourAngle / .pi
        return 12 + (daylightHours / 2)
    }

    private static func moonPhaseFraction(for date: Date) -> Double {
        let knownNewMoon = Date(timeIntervalSince1970: 947_182_440)
        let synodicMonth = 29.530588853 * 86_400
        let secondsSinceNewMoon = date.timeIntervalSince(knownNewMoon)
        let normalized = secondsSinceNewMoon.truncatingRemainder(dividingBy: synodicMonth)
        return normalized >= 0 ? normalized / synodicMonth : (normalized + synodicMonth) / synodicMonth
    }

    private static func moonPhaseName(for fraction: Double) -> String {
        switch fraction {
        case 0.00..<0.03, 0.97...1.00:
            return "New Moon"
        case 0.03..<0.22:
            return "Waxing Crescent"
        case 0.22..<0.28:
            return "First Quarter"
        case 0.28..<0.47:
            return "Waxing Gibbous"
        case 0.47..<0.53:
            return "Full Moon"
        case 0.53..<0.72:
            return "Waning Gibbous"
        case 0.72..<0.78:
            return "Last Quarter"
        default:
            return "Waning Crescent"
        }
    }

    private static func formattedHour(_ hour: Double) -> String {
        let clampedHour = max(0, min(hour, 23.99))
        let totalMinutes = Int((clampedHour * 60).rounded())
        let hourValue = (totalMinutes / 60) % 24
        let minuteValue = totalMinutes % 60
        let displayHour = hourValue == 0 ? 12 : (hourValue > 12 ? hourValue - 12 : hourValue)
        let period = hourValue >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", displayHour, minuteValue, period)
    }

    private static func formattedCoordinate(_ latitude: Double, _ longitude: Double) -> String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"
        return String(format: "%.2f°%@, %.2f°%@", abs(latitude), latDirection, abs(longitude), lonDirection)
    }
}
