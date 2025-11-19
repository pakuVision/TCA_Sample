//
//  Detail.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Detail {
    
    @ObservableState
    struct State: Equatable {
        let id: UUID
        let title: String
    }
    
    enum Action {
        case backButtonTapped
        case delegate(Delegate)
        
        enum Delegate {
            case requestPop // 부모에게 POP을 요청
        }
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                // delegate로 부모에게 요청
                return .send(.delegate(.requestPop))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct DetailView: View {
    let store: StoreOf<Detail>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Detail Screen")
                .font(.largeTitle)
            
            Text("Title: \(store.state.title)")
                .font(.title2)
            
            Button("Back Button") {
                store.send(.backButtonTapped)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .navigationTitle(store.state.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
