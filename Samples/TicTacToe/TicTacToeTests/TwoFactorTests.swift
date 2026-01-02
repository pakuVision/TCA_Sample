//
//  TwoFactorTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2026/01/02.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import TCASample

@MainActor
struct TwoFactorTests {

    @Test
    func happyPath() async {
        
        let store = TestStore(initialState: TwoFactor.State(token: "twofactor-token")) {
            TwoFactor()
        } withDependencies: {
            $0.authenticationClient.twoFactor = { @Sendable _, _ in
                AuthenticationResponse(token: "twofactor-token", twoFactorRequired: false)
            }
        }
        
        await store.send(\.view.binding.code, "1") {
            $0.code = "1"
        }
        await store.send(\.view.binding.code, "12") {
            $0.code = "12"
        }
        await store.send(\.view.binding.code, "123") {
            $0.code = "123"
        }
        await store.send(\.view.binding.code, "1234") {
            $0.code = "1234"
            $0.isFormValid = true
        }
        
        await store.send(\.view.submitButtonTapped) {
            $0.isTwoFactorRequestInFlight = true
        }
        
        await store.receive(\.twoFactorResponse.success) {
            $0.isTwoFactorRequestInFlight = false
        }
    }
    
    @Test
    func unhappyPath() async {
        let store = TestStore(initialState: TwoFactor.State(token: "twofactor-token")) {
            TwoFactor()
        } withDependencies: {
            $0.authenticationClient.twoFactor = { @Sendable _, _ in
                throw AuthenticationError.invalidTwoFactor
            }
        }
        
        await store.send(\.view.binding.code, "1234") {
            $0.code = "1234"
            $0.isFormValid = true
        }
        
        await store.send(\.view.submitButtonTapped) {
            $0.isTwoFactorRequestInFlight = true
        }
        
        await store.receive(\.twoFactorResponse.failure) {
            $0.isTwoFactorRequestInFlight = false
            $0.alert = AlertState {
                TextState(AuthenticationError.invalidTwoFactor.localizedDescription)
            }
        }
        
        await store.send(\.alert.dismiss) {
            $0.alert = nil
        }
        
        await store.finish()
    }
}
