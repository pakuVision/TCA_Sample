//
//  NewGameTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2026/01/02.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import TCASample

@MainActor
struct NewGameTests {

    @Test
    func integration() async {
        let store = TestStore(initialState: NewGame.State()) {
            NewGame()
        }
        
        await store.send(\.binding.oPlayerName, "park") {
            $0.oPlayerName = "park"
        }
        
        await store.send(\.binding.xPlayerName, "sato") {
            $0.xPlayerName = "sato"
        }
        
        await store.send(.letsPlayButtonTapped) {
            $0.game = Game.State(oPlayerName: "park", xPlayerName: "sato")
        }
        
        // x가 1,1좌표의 셀을 탭
        // -> board[1][1] 에 xPlayer가 들어잇는 것을 확인
        // -> current player가 o으로 전환된 것을 확인
        await store.send(\.game.cellTapped, (1,1)) {
            $0.game?.board[1][1] = .x
            $0.game?.currentPlayer = .o
        }
        
        await store.send(\.game.quitButtonTapped)
        await store.receive(\.game.dismiss) {
            $0.game = nil
        }
        
        // quit버튼을 눌러 게임을 종료 후 다시 게임을 시작할 수 있는지를 검증
        // quit -> restart 를 보장
        await store.send(.letsPlayButtonTapped) {
            $0.game = Game.State(oPlayerName: "park", xPlayerName: "sato")
        }
        
        await store.send(\.game.dismiss) {
            $0.game = nil
        }
        
        await store.send(.logoutButtonTapped)
    }
}
