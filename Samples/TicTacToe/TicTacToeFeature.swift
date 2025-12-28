//
//  TicTacToeFeature.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/21.
//

import ComposableArchitecture

// Enum기반 레듀서
// 여기에선 login과 newGame의 상태타입의 case가 존재
@Reducer
public enum TicTacToe {
    case login(Login)
    case newGame
    
    // 주의 enum타입의 레듀서에는 static으로 선언하고 있으니.
    // TicTacToe.body 로 바로 레듀서값을 취득할 수 있다.
    public static var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .login(.loginResponse(.success(response))) where !response.twoFactorRequired:
                state = .newGame
                return .none
            // .login상태 -> twoFactor가 표시되어있는 상태 -> Response.success 상태
            case .login(.twoFactor(.presented(.twoFactorResponse(.success)))):
                state = .newGame
                return .none
            case .login:
                return .none
            case .newGame:
                return .none
            }
        }
        //　state / action 이 현재 .login이라면 Login Reducer를 실행해줘!
        // enum이 아니라 일반 struct-based상태였다면
        // Scope(state: \.login, action: \.login) { Login() }  이렇게 사용
        .ifCaseLet(\.login, action: \.login) {
            Login()
        }
        .ifCaseLet(\.newGame, action: \.newGame) {
            
        }
    }
}
