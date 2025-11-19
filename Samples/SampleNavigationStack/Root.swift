//
//  RootFeature.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct RootFeature {
    
    // Path에 들어갈 수 있는 화면들을 정의
    @Reducer
    enum Path: Sendable {
        case detail(Detail)
        case settings(Settings)
    }
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var items: [String] = ["A", "B", "C"]
    }
    enum Action: Sendable {
        case path(StackActionOf<Path>)
        case itemTapped(String)
        case settingsButtonTapped
        case popToRoot
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .itemTapped(item):
                state.path.append(.detail(Detail.State(id: UUID(), title: item)))
                return .none
                
            case .settingsButtonTapped:
                // SettingsFeature 화면을 스택에 추가
                state.path.append(.settings(Settings.State()))
                return .none
                
            case .popToRoot:
                // 모든 스택을 제거하고 루트로 돌아감
                state.path.removeAll()
                return .none
                
            case .path(.element(_, action: .detail(.delegate(.requestPop)))):
                // Detail(자식) 로부터 action요청을 받음
                state.path.removeLast()
                return .none
                
            case .path:
                return .none
            }
        }
        // navigationStack의 각 화면들을 개별적으로 처리하는 TCA의 기능
        // path배열의 각 요소(화면)에 대해 해당 화면의 Reducer를 실행
        .forEach(\.path, action: \.path)
    }
}

extension RootFeature.Path.State: Equatable { }


struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                Section("Items") {
                    ForEach(store.items, id: \.self) { item in
                        Button(item) {
                            store.send(.itemTapped(item))
                        }
                    }
                }
                
                Section("Options") {
                    Button("Go to Settings") {
                        store.send(.settingsButtonTapped)
                    }
                    
                    if !store.path.isEmpty {
                        Button("Pop to Root") {
                            store.send(.popToRoot)
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Root")
        } destination: { store in
            
            switch store.case {
            case let .detail(detailStore):
                DetailView(store: detailStore)
            case let .settings(settingsStore):
                SettingsView(store: settingsStore)
            }
        }
    }
}
