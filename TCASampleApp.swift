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
        
//    static let store = Store(initialState: SearchFeature.State()) {
//        // Reducer를 생성
//        SearchFeature()
//    }
    
    static let store = Store(initialState: Todos.State()) {
        Todos() // Reducer
    }
    
    
    var body: some Scene {
        WindowGroup {
            TodosView(store: Self.store)
        }
    }
}
