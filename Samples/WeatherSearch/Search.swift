//
//  Search.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/21.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchFeature {
    
    @ObservableState
    struct State: Equatable {
        var results: [GeocodingSearch.Result] = []
        var searchQuery: String = ""
        
        var resultForecastRequestInFlight: GeocodingSearch.Result?
        var weather: Weather?
        
        struct Weather: Equatable {
          var id: GeocodingSearch.Result.ID
          var days: [Day]

          struct Day: Equatable {
            var date: Date
            var temperatureMax: Double
            var temperatureMaxUnit: String
            var temperatureMin: Double
            var temperatureMinUnit: String
          }
        }
    }
    
    enum Action {
        case searchQueryChangeDebounced
        case searchQueryChanged(String)
        case searchResponse(Result<GeocodingSearch, any Error>)
        case searchResultTapped(GeocodingSearch.Result)
        
        case forecastResponse(GeocodingSearch.Result.ID, Result<Forecast, any Error>)
    }
    
    @Dependency(\.weatherClient) var weatherClient
    
    private enum CancelID: String {
        case location
        case weather
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .forecastResponse(id, .success(forecast)):
                state.weather = State.Weather(id: id, days: forecast.daily.time.indices.map {
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
            case let .searchResultTapped(location):
                state.resultForecastRequestInFlight = location
                
                return .run { send in
                    await send(.forecastResponse(location.id, Result { try await weatherClient.forecast(location: location )}))
                }
                .cancellable(id: CancelID.weather, cancelInFlight: true)
            case let .searchResponse(.success(response)):
                print("data.count!: \(response.results.count)")
                state.results = response.results
                return .none
                
            case .searchResponse(.failure(_)):
                state.results = []
                state.weather = nil
                return .none
                
            case .searchQueryChangeDebounced:
                guard !state.searchQuery.isEmpty else { return .none }
                
                return .run { [query = state.searchQuery] send in
                    await send(.searchResponse(Result {
                        try await self.weatherClient.search(query: query)
                    }))
                }
                .cancellable(id: CancelID.location)
                
            case let .searchQueryChanged(searchQuery):
                state.searchQuery = searchQuery
                
                guard !state.searchQuery.isEmpty else {
                    state.results = []
                    return .cancel(id: CancelID.location)
                }
                
                return .none
                
            case .searchResponse:
                return .none
            case .forecastResponse:
                return .none
            }
        }
    }
}

struct SearchView: View {
    
    @Bindable var store: StoreOf<SearchFeature>
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    // searchQuery는 ObservableState이므로 액션으로 sending할 수 있음
                    TextField("Tokyo, Fujisawa, ...", text: $store.searchQuery.sending(\.searchQueryChanged))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                
                List {
                    ForEach(store.results) { location in
                        VStack(alignment: .leading) {
                            Button {
                                store.send(.searchResultTapped(location))
                            } label: {
                                HStack {
                                    Text(location.name)
                                    
                                    if store.resultForecastRequestInFlight?.id == location.id {
                                        ProgressView()
                                    }
                                }
                            }
                            
                            if location.id == store.weather?.id {
                                weatherView(locationWeather: store.weather)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .padding()
        }
        .task(id: store.searchQuery) {
            
            // searchQuery가 변경때마다 task호출됨
            // 0.3초 기다림 (기다리는 중에 이 태스크가 다시 호출되면 전task가 취소되고 새로운 task로 다시 시작)
            // searchQueryChangeDebounced Action을 보냄
            // .finish로 레듀서내의 effect가 끝날때까지 기다린다
            do {
                try await Task.sleep(for: .microseconds(300))
                
                // send동기실행
                let storeTask = store.send(.searchQueryChangeDebounced)
                
                // .finish를 사용하는 순간 await의 의미를 가진다.
                // 래듀서안의 액션처리의 .run이나 .cancellable의 모든 Effect가 종료될때 까지 Task는 기다린다
                await storeTask.finish()
            } catch { }
        }
    }
    
    @ViewBuilder
    func weatherView(locationWeather: SearchFeature.State.Weather?) -> some View {
        if let locationWeather {
            let days = locationWeather.days
                .enumerated()
                .map { index, weather in formattedWeather(day: weather, isToday: index == 0)}
            
            VStack(alignment: .leading) {
              ForEach(days, id: \.self) { day in
                Text(day)
              }
            }
            .padding(.leading, 16)
        }
    }
}

private func formattedWeather(day: SearchFeature.State.Weather.Day, isToday: Bool) -> String {
  let date =
    isToday
    ? "Today"
    : dateFormatter.string(from: day.date).capitalized
  let min = "\(day.temperatureMin)\(day.temperatureMinUnit)"
  let max = "\(day.temperatureMax)\(day.temperatureMaxUnit)"

  return "\(date), \(min) – \(max)"
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
