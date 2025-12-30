//
//  NewGame.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/28.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct NewGame {
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var game: Game.State?
        public var oPlayerName = ""
        public var xPlayerName = ""
    }
    
    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case game(PresentationAction<Game.Action>)
        case letsPlayButtonTapped
        case logoutButtonTapped
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .letsPlayButtonTapped:
                state.game = Game.State(oPlayerName: state.oPlayerName, xPlayerName: state.xPlayerName)
                return .none
                
            case .logoutButtonTapped:
                return .none
                
            case .game:
                return .none
            }
        }
        .ifLet(\.$game, action: \.game) {
            Game()
        }
    }
}
