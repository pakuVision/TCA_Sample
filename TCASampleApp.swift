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
    
    // MARK: SyncUps -----------------------------------------
    static let store = Store(initialState: SyncUpFeature.State()) {
        SyncUpFeature()
    }
    var body: some Scene {
        WindowGroup {
            SyncUpView(store: Self.store)
        }
    }
}
