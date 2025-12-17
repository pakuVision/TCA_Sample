//
//  SyncUpFormTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2025/12/17.
//

import Testing
import ComposableArchitecture
import Tagged
import Foundation

@testable import TCASample

@MainActor
struct SyncUpFormTests {

    init() { uncheckedUseMainSerialExecutor = true }
   
    @Test
    func addAttendee() async {
        let store = TestStore(
            initialState: SyncUpForm.State(syncUp: SyncUp(id: SyncUp.ID(), title: "Title", attendees: []))) {
                SyncUpForm()
            } withDependencies: {
                $0.uuid = .incrementing
            }
        
        // init시 상태확인
        store.assert {
            // syncup init내부에는 isEmpty의 경우 1개의 attendee가 추가되는 로직이 있으므로
            // uuid 0 인 attendee 하나가 들어있는 배열이어야 한다.
            $0.syncUp.attendees = [Attendee(id: Attendee.ID(UUID(0)))]
        }
        
        await store.send(.addAttendeeButtonTapped) {
            // 기본1개에서 2번째생성이니 uuid 1에 포커싱
            $0.focus = .attendee(Attendee.ID(UUID(1)))
            
            $0.syncUp.attendees = [
                Attendee(id: Attendee.ID(UUID(0))),
                Attendee(id: Attendee.ID(UUID(1)))
            ]
        }
    }
    
    @Test
    func focusAfterRemovingAttendee() async {
        let store = TestStore(
            initialState: SyncUpForm.State(
                syncUp: SyncUp(
                    id: SyncUp.ID(),
                    attendees: [
                        Attendee(id: Attendee.ID(), name: "A"),
                        Attendee(id: Attendee.ID(), name: "B"),
                        Attendee(id: Attendee.ID(), name: "C"),
                        Attendee(id: Attendee.ID(), name: "D")
                    ]
                )
            )
        ) {
            SyncUpForm()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        await store.send(.deleteAttendee(indexSet: [0])) {
            $0.focus = .attendee($0.syncUp.attendees[1].id)
            $0.syncUp.attendees = [
                $0.syncUp.attendees[1],
                $0.syncUp.attendees[2],
                $0.syncUp.attendees[3]
            ]
        }
        
        await store.send(.deleteAttendee(indexSet: [1])) {
            
            // 헛갈려하는 부분
            // 파라메터로 오는 $0(state) 는 삭제전의 상태이며
            // 이 스코프 안에는 기댓값을 $0에 ←에 설정을 해줘야 하는 거임
            // 그러니 focus에서 삭제 전의 uuid를 뽑아오는 행위임
            $0.focus = .attendee($0.syncUp.attendees[2].id)
            $0.syncUp.attendees = [
                $0.syncUp.attendees[0],
                $0.syncUp.attendees[2]
            ]
        }
        
        await store.send(.deleteAttendee(indexSet: [1])) {
            $0.focus = .attendee($0.syncUp.attendees[0].id)
            $0.syncUp.attendees = [
                $0.syncUp.attendees[0]
            ]
        }
        
        await store.send(.deleteAttendee(indexSet: [0])) {
            $0.focus = .attendee(Attendee.ID(UUID(0)))
            $0.syncUp.attendees = [
                Attendee(id: Attendee.ID(UUID(0)))
            ]
        }
    }
}
