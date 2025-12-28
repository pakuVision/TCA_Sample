//
//  LoginView.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/23.
//

import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    
    @Bindable var store: StoreOf<Login>
    
    var body: some View {
        Form {
            Text("ログインするには、メールアドレスは任意ものを使用し、パスワードは「password」で入力してください。\nメールアドレスに「2fa」という文字が含まれている場合は、二要素認証のフローに進みます。\nその画面では、コードとして「1234」を使用してください。")
            
            Section {
                TextField("example@gmail.com", text: $store.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                SecureField("••••••••", text: $store.password)
            }
            
            Button {
                store.send(.view(.loginButtonTapped))
            } label: {
                HStack {
                    Text("Log in")
                    if store.isActivityIndicatorVisible {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(store.isLoginButtonDisabled)
            .buttonStyle(.bordered)
        }
        .navigationTitle("Login")
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationDestination(item: $store.scope(state: \.twoFactor, action: \.twoFactor)) { store in
            TwoFactorView(store: store)
        }
    }
}

// 여기서 바로 state값을 사용하지 않고 한 단계 거치는 이유
// state.isFormValid같은 값은 상태(state)이고
// isLoginButtonDisabled 은 의미(의도)가 담긴 UI파생 값이기 때문이다.
// 이렇게 하는 이유는 view쪽에서는 isLoginButtonDisabled 만 알면 되는 것이녀 isFormValid의 상태까지는 몰라도 된다는 개념
extension Login.State {
    fileprivate var isLoginButtonDisabled: Bool { !self.isFormValid }
    fileprivate var isActivityIndicatorVisible: Bool { self.isLoginRequestInFlight }
}
