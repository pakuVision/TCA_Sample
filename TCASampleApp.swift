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
        
    static let store = Store(initialState: SearchFeature.State()) {
        // Reducer를 생성
        SearchFeature()
    }
    var body: some Scene {
        WindowGroup {
            SearchView(store: Self.store)
        }
    }
}
