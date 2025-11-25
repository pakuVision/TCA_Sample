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

struct Forecast: Decodable, Equatable, Sendable {
    var daily: Daily
    var dailyUnits: DailyUnits

    private enum CodingKeys: String, CodingKey {
            case daily
            case dailyUnits = "daily_units"  // ✅ 추가!
        }
    
    struct Daily: Decodable, Equatable, Sendable {
        
        private enum CodingKeys: String, CodingKey {
          case temperatureMax = "temperature_2m_max"
          case temperatureMin = "temperature_2m_min"
          case time
        }
        
        var temperatureMax: [Double]
        var temperatureMin: [Double]
        var time: [String]
    }
    
    struct DailyUnits: Decodable, Equatable, Sendable {
        
        private enum CodingKeys: String, CodingKey {
          case temperatureMax = "temperature_2m_max"
          case temperatureMin = "temperature_2m_min"
        }
        
        var temperatureMax: String
        var temperatureMin: String
    }
}

@DependencyClient
struct WeatherClient {
    var search: @Sendable (_ query: String) async throws -> GeocodingSearch
    var forecast: @Sendable (_ location: GeocodingSearch.Result) async throws -> Forecast
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
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try decoder.decode(GeocodingSearch.self, from: data)
        },
        forecast: { location in
            
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                .init(name: "latitude", value: "\(location.latitude)"),
                .init(name: "longitude", value: "\(location.longitude)"),
                .init(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
                .init(name: "timezone", value: TimeZone.autoupdatingCurrent.identifier)
            ]
            
            let decoder = JSONDecoder()
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try decoder.decode(Forecast.self, from: data)
        }
    )
}
