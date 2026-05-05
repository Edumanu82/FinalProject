//
//  AstronomyService.swift
//  FinalProject
//
//  Created by Carlos Fletes on 5/4/26.
//

import Foundation

struct AstronomyService {
    private let apiKey = "YOUR_API_NINJAS_KEY"

    func searchStars(name: String) async throws -> [StarResult] {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.api-ninjas.com/v1/stars?name=\(encodedName)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([StarResult].self, from: data)
    }
}

struct StarResult: Codable, Identifiable {
    var id: String { name }

    let name: String
    let constellation: String?
    let spectralClass: String?

    enum CodingKeys: String, CodingKey {
        case name
        case constellation
        case spectralClass = "spectral_class"
    }
}
