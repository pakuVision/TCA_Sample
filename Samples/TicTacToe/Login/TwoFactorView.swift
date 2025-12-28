//
//  TwoFactorView.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/28.
//

import ComposableArchitecture
import SwiftUI

public struct TwoFactorView: View {
    @Bindable public var store: StoreOf<TwoFactor>
    
    public var body: some View {
        Form {
            Text(#"To confirm the second Tactor enter "1234" into the form."#)
            
            Section {
                TextField("1234", text: $store.code)
                    .keyboardType(.numberPad)
            }
            
            HStack {
                Button("Submit") {
                    store.send(.view(.submitButtonTapped))
                }
                .disabled(store.isSubmitButtonDisabled)
                
                if store.isActivityIndicatorVisible {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .disabled(store.isFormDisabled)
        .navigationTitle("Confirmation Code")
    }
}

extension TwoFactor.State {
    fileprivate var isFormDisabled: Bool { self.isTwoFactorRequestInFlight }
    fileprivate var isActivityIndicatorVisible: Bool { self.isTwoFactorRequestInFlight }
    fileprivate var isSubmitButtonDisabled: Bool { !self.isFormValid }
}
