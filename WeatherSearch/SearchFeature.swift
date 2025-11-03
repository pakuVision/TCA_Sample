//
//  SearchFeature.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/03.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchFeature {

    @ObservableState
    struct State: Equatable {
        var results: [GeocodingSearch.Result] = []
        var isRequestingSearch = false
        var searchQuery = ""
        var errorMessage: String?
        
        // search로취득한 location버튼리스트에서 탭한 버튼에 프로그레스를 표시하기 위한 변수
        var resultForecastRequestInFlight: GeocodingSearch.Result?
        var weather: Weather?
        
        struct Weather: Equatable {
          var id: GeocodingSearch.Result.ID
          var days: [Day]

          struct Day: Equatable {
            var date: String
            var temperatureMax: Double
            var temperatureMaxUnit: String
            var temperatureMin: Double
            var temperatureMinUnit: String
          }
        }
    }
    
    enum Action {
        case searchQueryChanged(String)
        case searchQueryChangedDebounced
        case searchResponse(Result<GeocodingSearch, any Error>)
        
        case locationButtonTapped(GeocodingSearch.Result)
        case forecastResponse(GeocodingSearch.Result.ID, Result<Forecast, any Error>)
    }
    
    private enum CancelID {
        case search
        case forecast
    }
    
    // Reduce가 weather api를 사용하기 위해 필요
    @Dependency(\.weatherClient) var weatherClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
// searching location --------------------------------------------------
            case let .searchQueryChanged(query):
                state.searchQuery = query
                
                guard !state.searchQuery.isEmpty else {
                    state.results = []
                    return .none
                }
                return .none
                
            case .searchQueryChangedDebounced:
                guard !state.searchQuery.isEmpty else { return .none }
                state.isRequestingSearch = true
                return .run { [query = state.searchQuery] send in
                    await send(.searchResponse(Result {
                        try await self.weatherClient.search(query: query)
                    }))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)
                
            case let .searchResponse(.success(response)):
                state.isRequestingSearch = false
                state.results = response.results
                return .none
                
            case let .searchResponse(.failure(error)):
                state.isRequestingSearch = false
                state.errorMessage = "검색 실패: \(error.localizedDescription)"
                return .none
// searching location --------------------------------------------------

     
// fetching location's forecast --------------------------------------------------

            case let .locationButtonTapped(location):
                state.resultForecastRequestInFlight = location
                
                return .run { send in
                    await send(
                        .forecastResponse(
                            location.id,
                            Result { try await self.weatherClient.forecast(location: location) }
                        )
                    )
                }
                // cancelInFlight: 진행중인api를 캔슬
                .cancellable(id: CancelID.forecast, cancelInFlight: true)
                
            case  let .forecastResponse(id, .success(forecast)):
                print("successed forecastResponse")
                state.weather = State.Weather(
                    id: id,
                    days: forecast.daily.time.indices.map {
                      State.Weather.Day(
                        date: forecast.daily.time[$0],
                        temperatureMax: forecast.daily.temperatureMax[$0],
                        temperatureMaxUnit: forecast.dailyUnits.temperatureMax,
                        temperatureMin: forecast.daily.temperatureMin[$0],
                        temperatureMinUnit: forecast.dailyUnits.temperatureMin
                      )
                    })
                state.resultForecastRequestInFlight = nil
                return .none
                
            case let .forecastResponse(_, .failure(error)):
                state.resultForecastRequestInFlight = nil
                state.results = []
                state.errorMessage = "날씨 정보를 가져올 수 없습니다: \(error.localizedDescription)"
                print("failed forecastResponse: \(error.localizedDescription)")
                return .none
// fetching location's forecast --------------------------------------------------
            }
        }
    }
}
