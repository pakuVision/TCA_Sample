//
//  SyncUpDetailTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2025/12/15.
//

import ComposableArchitecture
import Foundation
import Testing
import Tagged
@testable import TCASample
internal import SwiftUI
internal import Speech

@MainActor
struct SyncUpDetailTests {

    init() { uncheckedUseMainSerialExecutor = true }
    
    
    // 음성인식이 거부된 상태에서 얼럿에서 설정 열기 버튼을 눌러 앱 설정을 여는 테스트
    // opensetting디펜던시가 호출되고 alert은 닫힌다 를 검증
    @Test
    func openSettings() async {
        
        // LockIsolated : 테스트환경에서 actor가 해주는 격리 + 직렬화 처리를
        // 가볍게 흉내 내기 위한 도구다.
        
        // async/await은 실행 순서를 비결정적으로 만들 수 있으므로
        // xptmxmdptms actor대신 LockIsolated를 사용해
        // 동기적이고 관찰 가능한 상태 보호를 한다.
        let settingsOpened = LockIsolated(false)
        
        let store = TestStore(initialState: SyncUpDetail.State(destination: .alert(.speechRecognitionDenied), syncUp: Shared(value: .mock))) {
            SyncUpDetail()
        } withDependencies: {
            $0.openSettings = { settingsOpened.setValue(true) }
            $0.speechClient.authorizationStatus = { .denied }
        }
        
        await store.send(\.destination.alert.openSettings) {
            
            // 얼럿이 표시되었는데 왜 destination == nil 상태냐?
            // TCA에서는 alert이 표시됨과 동시에 자동적으로 내부에서 destination = nil 됨
            
            // 하지만 sheet은 명시적으로 컨트롤해줘야 함
            $0.destination = nil
        }
        
        #expect(settingsOpened.value)
    }

    
    @Test
    func speechDenied() async throws {
        let store = TestStore(initialState: SyncUpDetail.State(syncUp: Shared(value: .mock))) {
            SyncUpDetail()
        } withDependencies: {
            $0.speechClient.authorizationStatus = { .denied }
        }
        
        await store.send(.startMeetingButtonTapped) {
            // speech denied 의 알람이 표시되어야 함
            $0.destination = .alert(.speechRecognitionDenied)
        }
    }
    
    @Test
    func speechRestricted() async {
        let store = TestStore(initialState: SyncUpDetail.State(syncUp: Shared(value: .mock))) {
            SyncUpDetail()
        } withDependencies: {
            $0.speechClient.authorizationStatus = { .restricted }
        }
        
        await store.send(.startMeetingButtonTapped) {
            $0.destination = .alert(.speechRecognitionRestricted)
        }
    }
    
    @Test
    func speechAuthorized() async {
        let store = TestStore(initialState: SyncUpDetail.State(syncUp: Shared(value: .mock))) {
            SyncUpDetail()
        } withDependencies: {
            $0.speechClient.authorizationStatus = { .authorized }
        }
        
        await store.send(.startMeetingButtonTapped)
        await store.receive(\.delegate.startMeeting)
    }
    
    @Test
    func edit() async {
        var syncUp = SyncUp.mock
        let store = TestStore(initialState: SyncUpDetail.State(syncUp: Shared(value: syncUp))) {
            SyncUpDetail()
        }
        
        // 1. edit버튼 누름
        // 2. 싱크업폼이 시트로 열림
        await store.send(.editButtonTapped) {
            $0.destination = .edit(SyncUpForm.State(syncUp: syncUp))
        }
        
        // 3. 타이틀을 수정
        syncUp.title = "update"
        
        // destination先のeditに渡された syncupと binding -> destination.edit내부의 값이 수정된 값과 같아야 함
        await store.send(\.destination.edit.binding.syncUp, syncUp) {
            $0.destination.modify(\.edit) {
                $0.syncUp.title = "update"
            }
        }
        
        await store.send(.doneEditingButtonTapped) {
            // 시트가 닫히고
            $0.destination = nil
            // 수정된 syncUp으로 갱신되었음을 확인
            $0.$syncUp.withLock { $0.title = "update" }
        }
    }
    
    @Test
    func delete() async throws {
        let syncUp = SyncUp.mock
        
        // .syncUps이라는 Shared Storage(전역공유상태) 에 syncUp 하나가 들어있는 배열을 넣음
        @Shared(.syncUps) var syncUps = [syncUp]
        
        // defer - 스코프 종료시 반드시 호출됨
        // 이것은 보통  리소스정리나, lock헤재, 상태복구등... 중간에 뭐가 일어났든 끝날때는 반드시 이 상태어야 할때 사용
        
        // 여기서의 defer는 이렇게 선언!
        // 이 테스트가 끝나는 시점에
        // syncUps는 반드시 비어있어야 한다!!!
        
        // defer가 dismiss이후를 보장하진 안지만 테스트 종료 시점을 보장
        defer { #expect(syncUps.isEmpty) }
        
        
        // Shared배열에서 특정요소를 바인딩
        // #require - 값이 없으면 테스트 즉시 실패 / 이 데이터가 반드시 있어야 한다는 선언
        let sharedSyncUp = try #require(Shared($syncUps[id: syncUp.id]))
        
        let store = TestStore(initialState: SyncUpDetail.State(syncUp: sharedSyncUp)) {
            SyncUpDetail()
        }
        
        await store.send(.deleteButtonTapped) {
            $0.destination = .alert(.deleteSyncUp)
        }
        
        await store.send(\.destination.alert.confirmDeletion) {
            $0.destination = nil
        }
        
        #expect(store.isDismissed)
    }
}
