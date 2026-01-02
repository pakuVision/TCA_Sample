//
//  LoginTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2026/01/02.
//

import Testing
import ComposableArchitecture

@testable import TCASample

@MainActor
struct LoginTests {
    
    @Test
    func twoFactorSuccess() async {
        let store = TestStore(initialState: Login.State()) {
            Login()
        } withDependencies: {
            $0.authenticationClient = .init(login: { email, password in
                AuthenticationResponse(token: "test-token", twoFactorRequired: true)
            }, twoFactor: { code, token in
                AuthenticationResponse(token: "test-token", twoFactorRequired: false)
            })
        }
        
        await store.send(\.view.binding.email, "test@gmail") { state in
            state.email = "test@gmail"
        }
        await store.send(\.view.binding.password, "password") { state in
            state.password = "password"
            state.isFormValid = true
        }
        
        let twoFactorPresentationTask = await store.send(\.view.loginButtonTapped) {
            $0.isLoginRequestInFlight = true
        }
        
        await store.receive(\.loginResponse.success) {
            $0.isLoginRequestInFlight = false
            $0.twoFactor = TwoFactor.State(token: "test-token")
        }
        
        await store.send(\.twoFactor.view.binding.code, "1234") {
            $0.twoFactor?.code = "1234"
            $0.twoFactor?.isFormValid = true
        }
        
        await store.send(\.twoFactor.view.submitButtonTapped) {
            $0.twoFactor?.isTwoFactorRequestInFlight = true
        }
        
        await store.receive(\.twoFactor.twoFactorResponse.success) {
            $0.twoFactor?.isTwoFactorRequestInFlight = false
        }
        
        
        // ⭐️ twoFactorPresentationTask를 캔슬로 종료하는 이유
        /*
         store.finish() (남아있는 effect가 없음을 보장) 를 사용하거나
         await store.send(\.twoFactor.dismiss) {
             $0.twoFactor = nil
         } 로 dismiss로 테스트를 종료해도 문제는 없지만
         
         여기에서 .cancel을 사용해서 종료한 이유는 아래와 같다.
         
         "로그인 플로우에서 Two-Factor인증이 성공적으로 처리되는 것 까지만 검증한다."
         "그 이후의 화면 닫힘(presentation종료)은 테스트 범위가 아니므로 남아있는 presentation Task는 cancel()로 정리(clean-up)한다."
         
         이렇게 의도를 명확히 한 "테스트 종료를 위한 정리(clean-up)이다."
         */
        

        await twoFactorPresentationTask.cancel()
    }
  
   

}
