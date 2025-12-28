//
//  TCASampleApp.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/10/31.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCASampleApp: App {
    
    // MARK: Root -----------------------------------------
    // NavigationStack + path로 간단한 화면천이 샘플
//    static let store = Store(initialState: RootFeature.State()) {
//        RootFeature()
//    }
//    var body: some Scene {
//        WindowGroup {
//            RootView(store: Self.store)
//        }
//    }
    
    // MARK: TODO -----------------------------------------
//    static let store = Store(initialState: Todos.State()) {
//        Todos() // Reducer
//    }
//    var body: some Scene {
//        WindowGroup {
//            TodosView(store: Self.store)
//        }
//    }
    
    // MARK: Search -----------------------------------------
//    static let searchStore = Store(initialState: SearchFeature.State()) {
//        SearchFeature()
//    }
//    
//    var body: some Scene  {
//        WindowGroup {
//            SearchView(store: Self.searchStore)
//        }
//    }
//    
    // MARK: SyncUps -----------------------------------------
//    static let store = Store(initialState: SyncUpFeature.State()) {
//        SyncUpFeature()
//    }
//    var body: some Scene {
//        WindowGroup {
//            SyncUpView(store: Self.store)
//        }
//    }
    
    // MARK: TicTacToe -----------------------------------------
    // static body 이므로 이렇게 바로 레듀서값을 취득가능하다.
    static let ticTacToeStore = Store(initialState: TicTacToe.State.login(Login.State())) {
        TicTacToe.body
    }
    
    var body: some Scene {
        WindowGroup {
            TicTacToeAppView(store: Self.ticTacToeStore)
        }
    }
}
