//
//  GameTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2026/01/02.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import TCASample

@MainActor
struct GameTests {

    @Test
    func winnerQuits() async {
        let store = TestStore(initialState: Game.State(oPlayerName: "park", xPlayerName: "sato")) {
            Game()
        }
        
        await store.send(.cellTapped(row: 0, column: 0)) {
            $0.board[0][0] = .x
            $0.currentPlayer = .o
        }
        
        await store.send(.cellTapped(row: 0, column: 1)) {
            $0.board[0][1] = .o
            $0.currentPlayer = .x
        }
        
        await store.send(.cellTapped(row: 1, column: 1)) {
            $0.board[1][1] = .x
            $0.currentPlayer = .o
        }
        
        await store.send(.cellTapped(row: 0, column: 2)) {
            $0.board[0][2] = .o
            $0.currentPlayer = .x
        }
        
        await store.send(.cellTapped(row: 2, column: 2)) {
            $0.board[2][2] = .x
            $0.currentPlayer = .o
            
        }
        
        #expect(store.state.board.hasWinner)
        #expect(store.state.board.hasWin(.x))
    
    }
}
