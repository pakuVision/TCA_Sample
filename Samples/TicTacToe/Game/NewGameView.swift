//
//  NewGameView.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/28.
//

import ComposableArchitecture
import SwiftUI

struct NewGameView: View {
    
    @Bindable var store: StoreOf<NewGame>
    
    var body: some View {
        Form {
            Section {
                TextField("Blob Sr.", text: $store.xPlayerName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textContentType(.name)
            } header: {
                Text("X Player Name")
            }
            
            Section {
                TextField("Blob Jr.", text: $store.oPlayerName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textContentType(.name)
            } header: {
                Text("O Player Name")
            }
            
            Button("Let's play!") {
                store.send(.letsPlayButtonTapped)
            }
            .buttonStyle(.bordered)
            .disabled(store.isLetsPlayButtonDisabled)
        }
        .navigationTitle("New Game")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Logout") {
                    store.send(.logoutButtonTapped)
                }
            }
        }
        .navigationDestination(item: $store.scope(state: \.game, action: \.game)) { store in
            GameView(store: store)
        }
    }
}

extension NewGame.State {
    fileprivate var isLetsPlayButtonDisabled: Bool {
        self.oPlayerName.isEmpty || self.xPlayerName.isEmpty
    }
}
