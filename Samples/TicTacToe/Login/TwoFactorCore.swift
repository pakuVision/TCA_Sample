//
//  TwoFactor.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/25.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct TwoFactor: Sendable {
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var code = ""
        public var isFormValid = false
        public var isTwoFactorRequestInFlight = false
        public let token: String
        
        public init(token: String) {
            self.token = token
        }
    }
    
    public enum Action: Sendable, ViewAction {
        case alert(PresentationAction<Alert>)
        case view(View)
        
        case twoFactorResponse(Result<AuthenticationResponse, any Error>)
        
        public enum Alert: Equatable, Sendable { }
        
        @CasePathable
        public enum View: BindableAction, Sendable {
            case binding(BindingAction<State>)
            case submitButtonTapped
        }
    }
    
    @Dependency(\.authenticationClient) var authenticationClient
    
    public var body: some Reducer<State, Action> {
        BindingReducer(action: \.view)
        
        Reduce { state, action in
            
            switch action  {
            case .view(.binding):
                state.isFormValid = state.code.count >= 4
                return .none
            case .view(.submitButtonTapped):
                state.isTwoFactorRequestInFlight = true
                return .run { [code = state.code, token = state.token] send in
                    await send(.twoFactorResponse(
                        await Result {
                            try await authenticationClient.twoFactor(code: code, token: token)
                        }
                    ))
                }
            case let .twoFactorResponse(.success(response)):
                state.isTwoFactorRequestInFlight = false
                return .none
            case let .twoFactorResponse(.failure(error)):
                state.alert = AlertState { TextState(error.localizedDescription) }
                state.isTwoFactorRequestInFlight = false
                return .none
            case .alert:
                return .none
                
            case .view:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
