//
//  LoginCore.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/21.
//

import ComposableArchitecture
import SwiftUI

/// Login Reducer
/// - Sendable을 선언함으로써 이 Reducer는 스레드(actor) 경계를 넘어 이동해도
///   안전해야 한다는 계약을 컴파일러와 맺는다.
/// - 컴파일러는 이 계약을 위반하는 코드가 발견되면
///   런타임 이전에 에러로 막아 사전에 concurrency 버그를 방지한다.
@Reducer
public struct Login {
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        @Presents public var twoFactor: TwoFactor.State?
        public var email = ""
        public var isFormValid = false
        public var isLoginRequestInFlight = false
        public var password = ""
        
    }

    // ViewAction을 채택하므로서
    // View -> Reducer 바인딩 경로가 명확해짐.
    // Action.view(.bidning(.set(\.email, newValue)))
    public enum Action: Sendable, ViewAction {
        case alert(PresentationAction<Alert>)

        // View에서 보낼 수 있는 Action을 제한
        // View는 오직 .view(...)만 보낼 수 있다.
        // 즉. View가 실수로 .loginResponse를 보내는 것을 컴파일 타임에 차단(에러를 발생) 하기 위한 계약같은 것
        // 이렇게 view로부터의 액션을 선언하면 레듀서 스위치에서 case .view(...) 처럼 바로 view에서의 action이라는 것을 바로 알수 있는 메리트가 있다.
        case view(View)
        
        case loginResponse(Result<AuthenticationResponse, any Error>)
        case twoFactor(PresentationAction<TwoFactor.Action>)
        
        public enum View: BindableAction, Sendable {
            case binding(BindingAction<State>)
            case loginButtonTapped
        }
        
        public enum Alert: Equatable, Sendable { }
    }
    
    @Dependency(\.authenticationClient) var authenticationClient
    
    public var body: some Reducer<State, Action> {
        BindingReducer(action: \.view)
        
        Reduce { state, action in
            switch action {
            case .alert:
                return .none

            case let .loginResponse(.success(response)):
                state.isLoginRequestInFlight = false
                if response.twoFactorRequired {
                    print("twoFactorRequired!!")
                    state.twoFactor = TwoFactor.State(token: response.token)
                }
                return .none
            case let .loginResponse(.failure(error)):
                state.alert = AlertState { TextState(error.localizedDescription) }
                state.isLoginRequestInFlight = false
                return .none
            case .view(.binding):
                state.isFormValid = !state.email.isEmpty && !state.password.isEmpty
                return .none
                
            case .view(.loginButtonTapped):
                print("login button tapped!")
                state.isLoginRequestInFlight = true
                
                return .run { [email = state.email, password = state.password] send in
                    await send(.loginResponse(
                        Result {
                            try await self.authenticationClient.login(email: email, password: password)
                        }
                    ))
                }
                
            case .twoFactor:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        // state.twoFactor가 nil이 아닐 때, 해당 상태와 액션을 TwoFactor리듀서로 위임한다 라는 의미
        .ifLet(\.$twoFactor, action: \.twoFactor) {
            // @Presents public var twoFactor: TwoFactor.State?
            // 자식 twoFactor의 상태를 옵셔널로 보관하고 있기에  여기(Parent tree)아래에 연결
            TwoFactor()
        }
    }
}
