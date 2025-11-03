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
        var isLoading = false
        var searchQuery = ""
        var errorMessage: String?
    }
    
    enum Action {
        case searchQueryChanged(String)
        case searchQueryChangedDebounced
        case searchResponse(Result<GeocodingSearch, any Error>)
    }
    
    // Reduce가 weather api를 사용하기 위해 필요
    @Dependency(\.weatherClient) var weatherClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .searchQueryChanged(query):
                state.searchQuery = query
                
                guard !state.searchQuery.isEmpty else {
                    state.results = []
                    return .none
                }
                return .none
                
            case .searchQueryChangedDebounced:
                guard !state.searchQuery.isEmpty else { return .none }
                state.isLoading = true
                return .run { [query = state.searchQuery] send in
                    await send(.searchResponse(Result {
                        try await self.weatherClient.search(query: query)
                    }))
                }
                
            case let .searchResponse(.success(response)):
                state.isLoading = false
                state.results = response.results
                return .none
                
            case let .searchResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "\(error.localizedDescription)"
                return .none
            }
            
        }
    }
}
