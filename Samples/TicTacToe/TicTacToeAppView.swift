//
//  TicTacToeAppView.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/21.
//

import ComposableArchitecture
import SwiftUI

struct TicTacToeAppView: View {
    let store: StoreOf<TicTacToe>
    
    var body: some View {
        switch store.case {
        case let .login(store):
            NavigationStack {
                LoginView(store: store)
            }
        case let .newGame(store):
            NavigationStack {
                NewGameView(store: store)
            }
        }
    }
}
