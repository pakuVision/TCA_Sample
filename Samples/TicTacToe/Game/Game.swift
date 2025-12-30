//
//  Game.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/28.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct Game: Sendable {
    
    @ObservableState
    public struct State: Equatable {
        public var board: Three<Three<Player?>> = .empty
        public var currentPlayer: Player = .x
        public var oPlayerName: String
        public var xPlayerName: String
    }
    
    public enum Action: Sendable {
        case cellTapped(row: Int, column: Int)
        case playAgainButtonTapped
        case quitButtonTapped
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .cellTapped(row, column):
                print("cell tapped!!: row:\(row), column:\(column)")
                
                guard state.board[row][column] == nil, !state.board.hasWinner else { return .none }
                
                state.board[row][column] = state.currentPlayer
               
                state.currentPlayer.toggle()
                
                return .none
            case .playAgainButtonTapped:
                state.board = .empty
                return .none
            case .quitButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}


extension Game.State {
    fileprivate var currentPlayerName: String {
        switch self.currentPlayer {
        case .o: return oPlayerName
        case .x: return xPlayerName
        }
    }
    
    fileprivate var title: String {
        "Title"
    }
}

public enum Player: Equatable, Sendable {
    case o
    case x
    
    public mutating func toggle() {
        switch self {
        case .o: self = .x
        case .x: self = .o
        }
    }
    
    public var label: String {
        switch self {
        case .o: return "⭕️"
        case .x: return "❌"
        }
    }
}
