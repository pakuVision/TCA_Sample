//
//  Untitled.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/02.
//

import ComposableArchitecture
import SwiftUI



struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                searchSection
                    .padding(.horizontal, 16)
                
                ZStack {
                    contentSection

                    if store.isRequestingSearch {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Search Location's Weather")
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        // id에 query값을 설정하므로서 값이 바뀌면 task가 자동 취소되는 기능
        .task(id: store.searchQuery) {
            do {
                // 1. searchQuery가 변경될때마다 이전Task가 취소되고 새로운Task가 시작
                // 2. 0.3초대기 (이 동안 추가입력이 없으면 send를 실행.  (추가입력이 들어오면 현Task가 취소되고 다시 0.3초간 대기)
                try await Task.sleep(for: .seconds(0.3))
                
                // finish()를 호출하는 이유
                // 1. searchQueryChangedDebounced는 .run { } 의 비동기 api의 호출 처리의 Effect를 발생시키는데
                //    비동기이므로 바로 다음 코드가 실행이 되어 버린다 (await이 붙어있어 혼동하기 쉽다)
                //    .finish를 실행하면, Effect의 결과값이 반환될 때까지 기다림
                
                // 2. query값이 바뀌면 현task가 취소되지만 Effect처리가 백그라운드에 남게되어 고아가 되는 이미지이다.
                //    .finish를 호출하므로서 task가 취소되면 자식의 Effect비동기 처리도 같이 취소시켜준다.
                
                await store.send(.searchQueryChangedDebounced).finish()
            } catch {
                // query값이 바뀌는 것으로 task.sleep은  CancellationError를 발생해서 여기서 catch하지만.
                // 핸들링 불필요하므로 catch는 빈 공간으로 남겨둔다.
            }
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("New York, San Francisco, ...", text: $store.searchQuery.sending(\.searchQueryChanged))
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
    
    private var contentSection: some View {
        List {
            ForEach(store.results) { location in
                locationButton(location)
            }
        }
    }
    
    @ViewBuilder
    private func locationButton(_ location: GeocodingSearch.Result) -> some View {
        Button {
            store.send(.locationButtonTapped(location))
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(location.name)
                    if store.resultForecastRequestInFlight?.id == location.id {
                        ProgressView()
                    }
                }
                if location.id == store.weather?.id {
                    weatherView(store.weather)
                        .foregroundStyle(.black)
                }
            }
        }
    }
    
    @ViewBuilder
    func weatherView(_ weather: SearchFeature.State.Weather?) -> some View {
        if let weather {
          let days = weather.days
            .enumerated()
            .map { idx, weather in formattedWeather(day: weather, isToday: idx == 0) }

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
    : day.date
  let min = "\(day.temperatureMin)\(day.temperatureMinUnit)"
  let max = "\(day.temperatureMax)\(day.temperatureMaxUnit)"

  return "\(date), \(min) – \(max)"
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
