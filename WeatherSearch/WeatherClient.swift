//
//  WeatherClient.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/02.
//

import ComposableArchitecture
import Foundation

struct GeocodingSearch: Decodable, Equatable, Sendable {
  var results: [Result]

  struct Result: Decodable, Equatable, Identifiable, Sendable {
    var country: String
    var latitude: Double
    var longitude: Double
    var id: Int
    var name: String
    var admin1: String?
  }
}

@DependencyClient
struct WeatherClient {
    var search: @Sendable (_ query: String) async throws -> GeocodingSearch
}

extension DependencyValues {
    var weatherClient: WeatherClient {
        get { self[WeatherClient.self] }
    }
}

extension WeatherClient: DependencyKey {
    static let liveValue = WeatherClient(
        search: { query in
            
           var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            components.queryItems = [
                .init(name: "name", value: query)
            ]
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try decoder.decode(GeocodingSearch.self, from: data)
        })
}
