//
//  TicTacToeFeatureTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2025/12/30.
//

import ComposableArchitecture
import Testing
import Foundation

@testable import TCASample

@MainActor
struct TicTacToeFeatureTests {

    @Test
    func integration() async {
        let store = TestStore(initialState: TicTacToe.State.login(Login.State())) {
            TicTacToe.body
        } withDependencies: {
            $0.authenticationClient.login = { @Sendable _, _  in
    
                return AuthenticationResponse(token: "test-token", twoFactorRequired: false)
            }
        }
        
        await store.send(\.login.view.binding.email, "test@gmail.com") { state in
            state = TicTacToe.State.login(Login.State(email: "test@gmail.com"))
            
            // modify사용법
//            state.modify(\.login) { loginState in
//                loginState.email = "test@gmail.com"
//            }
        }
        
        await store.send(\.login.view.binding.password, "password") { state in
            state = TicTacToe.State.login(Login.State(
                email: "test@gmail.com",
                isFormValid: true,
                password: "password")
            )
            
            // modify
            // 위의 경우는 State를 새로 넣기때문에 email까지설정해야 하지만
            // modify의 경우는 이미 email이 들어있으므로 필요없다.
//            state.modify(\.login) { inoutLoginState in
//                inoutLoginState.password = "password"
//                inoutLoginState.isFormValid = true
//            }
        }
        
        // effect가 발생시키면 반드시 이후에 receive를 해서 발생한 이벤트를 finish(소비)해야 한다.
        await store.send(\.login.view.loginButtonTapped) {
            $0.modify(\.login, yield: { loginState in
                loginState.isLoginRequestInFlight = true
            })
        }
        
        // ⚠️위에서 .run으로 발생시킨 Action을 여기에서 소비하지 않으면
        // 이에러가 발생하고 테스트가 실패된다.
        // Test failure: An effect returned 1 action that was not expected...
        await store.receive(\.login.loginResponse.success) {
            $0 = .newGame(NewGame.State())
        }
        
        await store.send(\.newGame.binding.oPlayerName, "park") { state in
            state.modify(\.newGame, yield: { newGameState in
                newGameState.oPlayerName = "park"
            })
        }
        
        await store.send(\.newGame.binding.xPlayerName, "sato") { state in
            state.modify(\.newGame, yield: { newGameState in
                newGameState.xPlayerName = "sato"
            })
        }
        
        await store.send(\.newGame.letsPlayButtonTapped) { state in
            state.modify(\.newGame, yield: { newGameState in
                newGameState.game = Game.State(oPlayerName: "park", xPlayerName: "sato")
            })
        }
        
        await store.send(\.newGame.logoutButtonTapped) { state in
            state = .login(Login.State())
        }
    }
}
