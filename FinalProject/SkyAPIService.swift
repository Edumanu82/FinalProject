//
//  SkyAPIService.swift
//  FinalProject
//
//

import CoreLocation
import Foundation

struct SkyAPIService {
    private let session: URLSession
    private let imageCache = SkyImageCache()

    init(session: URLSession = .shared) {
        self.session = session
    }

    var hasAstronomyCredentials: Bool {
        AppConfiguration.hasAstronomyCredentials
    }

    func fetchLiveConditions(for coordinate: CLLocationCoordinate2D) async throws -> SkyConditions {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,cloud_cover,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "visibility"),
            URLQueryItem(name: "daily", value: "sunrise,sunset"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]

        guard let url = components?.url else {
            throw SkyAPIError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let forecast = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)

        let visibilityMeters = forecast.hourly.visibility.first ?? 0
        return SkyConditions(
            temperatureText: "\(Int(forecast.current.temperature2M.rounded()))°C",
            cloudCoverText: "\(forecast.current.cloudCover)%",
            windText: "\(Int(forecast.current.windSpeed10M.rounded())) km/h",
            visibilityText: visibilityLabel(for: visibilityMeters),
            sunriseText: formatClockTime(forecast.daily.sunrise.first),
            sunsetText: formatClockTime(forecast.daily.sunset.first)
        )
    }

    func searchLocation(named query: String) async throws -> LocationSearchResult {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            throw SkyAPIError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let geocoding = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)

        guard let result = geocoding.results?.first else {
            throw SkyAPIError.locationNotFound
        }

        return LocationSearchResult(
            displayName: [result.name, result.admin1, result.country]
                .compactMap { $0 }
                .joined(separator: ", "),
            coordinate: CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
        )
    }

    func fetchVisibleBodies(for coordinate: CLLocationCoordinate2D, on date: Date) async throws -> [CelestialObject] {
        guard hasAstronomyCredentials else { return [] }

        var components = URLComponents(string: "https://api.astronomyapi.com/api/v2/bodies/positions")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "elevation", value: "0"),
            URLQueryItem(name: "from_date", value: dateFormatter.string(from: date)),
            URLQueryItem(name: "to_date", value: dateFormatter.string(from: date)),
            URLQueryItem(name: "time", value: timeFormatter.string(from: date)),
            URLQueryItem(name: "output", value: "rows")
        ]

        guard let url = components?.url else {
            throw SkyAPIError.invalidRequest
        }

        let (data, response) = try await session.data(for: authorizedRequest(url: url))
        try validateAstronomy(response: response)
        let bodyResponse = try JSONDecoder().decode(AstronomyBodiesResponse.self, from: data)

        let visibleRows = bodyResponse.data.table.rows.compactMap { row -> CelestialObject? in
            guard
                let firstCell = row.cells.first,
                let altitudeValue = Double(firstCell.position.altitude.degrees),
                altitudeValue > 0,
                supportedPlanetNames.contains(row.entry.name.lowercased())
            else {
                return nil
            }

            let constellationName = firstCell.position.constellation?.name ?? "the current sky"
            let detail = "Altitude \(Int(altitudeValue.rounded()))° in \(constellationName)"
            return CelestialObject(
                name: row.entry.name,
                type: "Planet",
                timeVisible: detail,
                sfSymbol: "globe.americas.fill",
                dataSource: .live
            )
        }
        .sorted { left, right in
            let leftAltitude = Int(left.timeVisible.split(separator: " ").dropFirst().first?.dropLast() ?? "0") ?? 0
            let rightAltitude = Int(right.timeVisible.split(separator: " ").dropFirst().first?.dropLast() ?? "0") ?? 0
            return leftAltitude > rightAltitude
        }

        return Array(visibleRows.prefix(3))
    }

    func searchAstronomyObjects(term: String) async throws -> [SearchableSkyObject] {
        guard hasAstronomyCredentials else { return [] }

        var results: [SearchableSkyObject] = []

        if supportedPlanetNames.contains(term.lowercased()) {
            results.append(
                SearchableSkyObject(
                    name: term.capitalized,
                    type: "Planet",
                    summary: "Live planet searches are supported through AstronomyAPI body positions.",
                    visibilityTip: "Use your location and time to check if this planet is currently above your horizon.",
                    tags: ["planet", "astronomyapi", "live"],
                    dataSource: .live
                )
            )
        }

        var components = URLComponents(string: "https://api.astronomyapi.com/api/v2/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "match_type", value: "fuzzy"),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "order_by", value: "name")
        ]

        guard let url = components?.url else {
            throw SkyAPIError.invalidRequest
        }

        let (data, response) = try await session.data(for: authorizedRequest(url: url))
        try validateAstronomy(response: response)
        let searchResponse = try JSONDecoder().decode(AstronomySearchResponse.self, from: data)

        let mapped = searchResponse.data.map { item in
            SearchableSkyObject(
                name: item.name,
                type: item.type.name,
                summary: item.crossIdentification?.prefix(3).map(\.name).joined(separator: ", ") ?? "Live astronomy catalog result.",
                visibilityTip: item.position.constellation.map { "Located in \($0.name)." } ?? "Check local sky conditions for the best observing window.",
                tags: [
                    item.position.constellation?.name,
                    item.subType?.id,
                    item.type.name
                ].compactMap { $0 },
                dataSource: .live
            )
        }

        results.append(contentsOf: mapped)
        return results
    }

    func enrichSearchableObjectsWithImages(_ objects: [SearchableSkyObject]) async throws -> [SearchableSkyObject] {
        try await withThrowingTaskGroup(of: (UUID, URL?).self) { group in
            for object in objects {
                let objectID = object.id
                let query = "\(object.name) \(object.type)"
                group.addTask {
                    let imageURL = try await searchableImageURL(for: object, query: query)
                    return (objectID, imageURL)
                }
            }

            var resolvedImages = [UUID: URL]()
            for try await (id, url) in group {
                resolvedImages[id] = url
            }

            return objects.map { object in
                var updated = object
                updated.imageURL = resolvedImages[object.id] ?? object.imageURL
                return updated
            }
        }
    }

    func enrichObjectsWithImages(_ objects: [CelestialObject]) async throws -> [CelestialObject] {
        try await withThrowingTaskGroup(of: (UUID, URL?).self) { group in
            for object in objects {
                let objectID = object.id
                let query = "\(object.name) \(object.type)"
                group.addTask {
                    let imageURL = try await imageURL(for: object, query: query)
                    return (objectID, imageURL)
                }
            }

            var resolvedImages = [UUID: URL]()
            for try await (id, url) in group {
                resolvedImages[id] = url
            }

            return objects.map { object in
                var updated = object
                updated.imageURL = resolvedImages[object.id] ?? object.imageURL
                return updated
            }
        }
    }

    private func imageURL(for object: CelestialObject, query: String) async throws -> URL? {
        try await resolvedImageURL(query: query) { items in
            bestImageURL(from: items, for: object)
        }
    }

    private func searchableImageURL(for object: SearchableSkyObject, query: String) async throws -> URL? {
        try await resolvedImageURL(query: query) { items in
            bestImageURL(from: items, for: object)
        }
    }

    private func resolvedImageURL(
        query: String,
        picker: ([NASAImageSearchResponse.Item]) -> URL?
    ) async throws -> URL? {
        if let cached = await imageCache.url(for: query) {
            return cached
        }

        var components = URLComponents(string: "https://images-api.nasa.gov/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "media_type", value: "image"),
            URLQueryItem(name: "page_size", value: "8")
        ]

        guard let url = components?.url else {
            throw SkyAPIError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let searchResponse = try JSONDecoder().decode(NASAImageSearchResponse.self, from: data)
        let previewURL = picker(searchResponse.collection.items)

        await imageCache.insert(previewURL, for: query)
        return previewURL
    }

    private func bestImageURL(from items: [NASAImageSearchResponse.Item], for object: CelestialObject) -> URL? {
        let scored = items.compactMap { item -> (score: Int, url: URL?)? in
            let score = score(item: item, for: object)
            return score > 0 ? (score, item.links?.first(where: { $0.render == "image" || $0.rel == "preview" })?.href) : nil
        }
        .sorted { $0.score > $1.score }

        guard let best = scored.first, best.score >= 10 else {
            return nil
        }

        return best.url
    }

    private func bestImageURL(from items: [NASAImageSearchResponse.Item], for object: SearchableSkyObject) -> URL? {
        let scored = items.compactMap { item -> (score: Int, url: URL?)? in
            let score = score(item: item, objectName: object.name, objectType: object.type)
            return score > 0 ? (score, item.links?.first(where: { $0.render == "image" || $0.rel == "preview" })?.href) : nil
        }
        .sorted { $0.score > $1.score }

        guard let best = scored.first, best.score >= 10 else {
            return nil
        }

        return best.url
    }

    private func score(item: NASAImageSearchResponse.Item, for object: CelestialObject) -> Int {
        score(item: item, objectName: object.name, objectType: object.type)
    }

    private func score(item: NASAImageSearchResponse.Item, objectName: String, objectType: String) -> Int {
        guard let metadata = item.data.first else { return 0 }

        let searchableText = [
            metadata.title,
            metadata.description,
            metadata.keywords?.joined(separator: " ")
        ]
        .compactMap { $0?.lowercased() }
        .joined(separator: " ")

        let objectName = objectName.lowercased()
        let objectType = objectType.lowercased()
        var score = 0

        if searchableText.contains(objectName) { score += 12 }
        if searchableText.contains(objectType) { score += 6 }

        for token in preferredTokens(objectName: objectName, objectType: objectType) where searchableText.contains(token) {
            score += 4
        }

        for token in bannedTokens where searchableText.contains(token) {
            score -= 8
        }

        if metadata.title?.lowercased().contains(objectName) == true {
            score += 8
        }

        return score
    }

    private func preferredTokens(for object: CelestialObject) -> [String] {
        preferredTokens(objectName: object.name.lowercased(), objectType: object.type.lowercased())
    }

    private func preferredTokens(objectName: String, objectType: String) -> [String] {
        switch objectType {
        case "planet":
            return ["planet", "solar system", objectName]
        case "constellation":
            return ["constellation", "stars", objectName]
        case "star":
            return ["star", objectName]
        case "galaxy":
            return ["galaxy", objectName]
        case "nebula":
            return ["nebula", objectName]
        default:
            return [objectName, objectType]
        }
    }

    private var bannedTokens: [String] {
        ["rocket", "launch", "astronaut", "spacecraft", "capsule", "crew", "mission patch", "booster", "runway", "aircraft"]
    }

    private var supportedPlanetNames: Set<String> {
        ["mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune"]
    }

    private func authorizedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        let credential = "\(AppConfiguration.astronomyApplicationID):\(AppConfiguration.astronomyApplicationSecret)"
        let encoded = Data(credential.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw SkyAPIError.invalidResponse
        }
    }

    private func validateAstronomy(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SkyAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw SkyAPIError.authenticationFailed
        default:
            throw SkyAPIError.invalidResponse
        }
    }

    private func visibilityLabel(for visibilityMeters: Double) -> String {
        let visibilityKilometers = visibilityMeters / 1_000

        switch visibilityKilometers {
        case 16...:
            return "Excellent visibility"
        case 10..<16:
            return "Good visibility"
        case 5..<10:
            return "Fair visibility"
        default:
            return "Hazy conditions"
        }
    }

    private func formatClockTime(_ value: String?) -> String {
        guard
            let value,
            let date = ISO8601DateFormatter().date(from: value)
        else {
            return "--"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

enum SkyAPIError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case locationNotFound
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The sky data request could not be created."
        case .invalidResponse:
            return "Live sky data could not be loaded."
        case .locationNotFound:
            return "I couldn't find that location. Try a city name like Seattle or Los Angeles."
        case .authenticationFailed:
            return "AstronomyAPI rejected the credentials. Double-check the Application ID and Secret, then clean and rebuild the app."
        }
    }
}

struct LocationSearchResult {
    let displayName: String
    let coordinate: CLLocationCoordinate2D
}

actor SkyImageCache {
    private var storage: [String: URL] = [:]

    func url(for query: String) -> URL? {
        storage[query]
    }

    func insert(_ url: URL?, for query: String) {
        storage[query] = url
    }
}

private struct OpenMeteoForecastResponse: Decodable {
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather

    struct CurrentWeather: Decodable {
        let temperature2M: Double
        let cloudCover: Int
        let windSpeed10M: Double

        enum CodingKeys: String, CodingKey {
            case temperature2M = "temperature_2m"
            case cloudCover = "cloud_cover"
            case windSpeed10M = "wind_speed_10m"
        }
    }

    struct HourlyWeather: Decodable {
        let visibility: [Double]
    }

    struct DailyWeather: Decodable {
        let sunrise: [String]
        let sunset: [String]
    }
}

private struct NASAImageSearchResponse: Decodable {
    let collection: Collection

    struct Collection: Decodable {
        let items: [Item]
    }

    struct Item: Decodable {
        let data: [Metadata]
        let links: [Link]?
    }

    struct Metadata: Decodable {
        let title: String?
        let description: String?
        let keywords: [String]?
    }

    struct Link: Decodable {
        let href: URL?
        let rel: String?
        let render: String?
    }
}

private struct OpenMeteoGeocodingResponse: Decodable {
    let results: [Result]?

    struct Result: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let admin1: String?
        let country: String?
    }
}

private struct AstronomyBodiesResponse: Decodable {
    let data: BodyData

    struct BodyData: Decodable {
        let table: Table
    }

    struct Table: Decodable {
        let rows: [Row]
    }

    struct Row: Decodable {
        let entry: Entry
        let cells: [Cell]
    }

    struct Entry: Decodable {
        let id: String
        let name: String
    }

    struct Cell: Decodable {
        let position: PositionContainer

        enum CodingKeys: String, CodingKey {
            case position = "position"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
            if let horizontalKey = DynamicCodingKeys(stringValue: "horizontal"), container.contains(horizontalKey) {
                let horizontal = try container.decode(HorizontalPosition.self, forKey: horizontalKey)
                let constellation = try container.decodeIfPresent(Constellation.self, forKey: DynamicCodingKeys(stringValue: "constellation")!)
                position = PositionContainer(altitude: horizontal.altitude, azimuth: horizontal.azimuth, constellation: constellation)
            } else if let typoKey = DynamicCodingKeys(stringValue: "horizonal"), container.contains(typoKey) {
                let horizontal = try container.decode(HorizontalPosition.self, forKey: typoKey)
                let constellation = try container.decodeIfPresent(Constellation.self, forKey: DynamicCodingKeys(stringValue: "constellation")!)
                position = PositionContainer(altitude: horizontal.altitude, azimuth: horizontal.azimuth, constellation: constellation)
            } else {
                position = PositionContainer(
                    altitude: AngularValue(degrees: "-90", string: "-90°"),
                    azimuth: AngularValue(degrees: "0", string: "0°"),
                    constellation: nil
                )
            }
        }
    }

    struct PositionContainer {
        let altitude: AngularValue
        let azimuth: AngularValue
        let constellation: Constellation?
    }

    struct HorizontalPosition: Decodable {
        let altitude: AngularValue
        let azimuth: AngularValue
    }

    struct AngularValue: Decodable {
        let degrees: String
        let string: String
    }

    struct Constellation: Decodable {
        let id: String
        let short: String
        let name: String
    }
}

private struct AstronomySearchResponse: Decodable {
    let data: [Item]

    struct Item: Decodable {
        let name: String
        let type: ItemType
        let subType: SubType?
        let crossIdentification: [CrossIdentifier]?
        let position: ItemPosition
    }

    struct ItemType: Decodable {
        let id: String
        let name: String
    }

    struct SubType: Decodable {
        let id: String
    }

    struct CrossIdentifier: Decodable {
        let name: String
        let catalogId: String?
    }

    struct ItemPosition: Decodable {
        let constellation: AstronomyBodiesResponse.Constellation?
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
