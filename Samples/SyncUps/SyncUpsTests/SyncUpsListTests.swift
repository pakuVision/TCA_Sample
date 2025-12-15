//
//  SyncUpsListTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2025/12/13.
//

import ComposableArchitecture
import Foundation
import Testing
import Tagged
@testable import TCASample
internal import SwiftUI
internal import Speech

@MainActor
struct SyncUpsListTests {

    /*
     테스트 항목
     - add버튼
     - cardView눌러서 detail천이
     - cardView 드래그해서 delete
     
     */
    
    init() { uncheckedUseMainSerialExecutor = true }

    @Test
    func add() async throws {
        let store = TestStore(initialState: SyncUpsList.State()) {
            SyncUpsList()
        } withDependencies: {
            
            // uuid값을 예측 가능하게 순차적으로 값을 증가시킴
            /*
             첫 번째 uuid() → UUID(00000000-0000-0000-0000-000000000000)
             두 번째 uuid() → UUID(00000000-0000-0000-0000-000000000001)
             세 번째 uuid() → UUID(00000000-0000-0000-0000-000000000002) ...
             */
            $0.uuid = .incrementing
        }
        
        var syncUp = SyncUp(id: SyncUp.ID(UUID(0)), attendees: [
            Attendee(id: Attendee.ID(UUID(1)))
        ])
        
        await store.send(.addSyncUpButtonTapped) {
            $0.destination = .add(SyncUpForm.State(syncUp: syncUp))
        }
        
        syncUp.title = "Add syncUp"
        
        // \.destination.add.binding.syncUp
        // Form에서 사용자가 입력한 값을 Form.State에 반영한다.
        // xxx - syncups수정을 해서는 안된다.
        await store.send(\.destination.add.binding.syncUp, syncUp) {
            $0.destination?.modify(\.add) { $0.syncUp.title = "Add syncUp" }
        }
        
        syncUp.attendees = [Attendee(id: Attendee.ID(UUID(2)))]
        await store.send(.confirmAddSyncUpButtonTapped) {
            $0.$syncUps.withLock { $0 = [syncUp] }
            $0.destination = nil

        }
    }
    
    @Test
    func addAndConfirmValidatesAttendees() async throws {
        @Dependency(\.uuid) var uuid
        
        let store = TestStore(
            initialState: SyncUpsList.State(
                destination: .add(SyncUpForm.State(syncUp: SyncUp(id: SyncUp.ID(uuidString: "00000000-0000-0000-0000-000000000123")!,
                                                                  title: "Design",
                                                                  attendees: [
                                                                    
                                                                    // name이 invalied이므로 이 코드는 실제 비지니스 로직에서 삭제되고 내부의 로직에서 디폴트 값이 생성이된다
                                                                    // 이 때 uuid는 세번째 호출이 되므로 uuid(2)가 되는 것을 검증 하면 된다.
                                                                    Attendee(id: Attendee.ID(uuid()), name: ""),
                                                                    Attendee(id: Attendee.ID(uuid()), name: "   ")
                                                                  ], meetings: [])))
            )
        ) {
            SyncUpsList()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        await store.send(.confirmAddSyncUpButtonTapped) {
            $0.destination = nil
            
            $0.$syncUps.withLock {
                $0 = [
                    .init(
                        id: SyncUp.ID(uuidString: "00000000-0000-0000-0000-000000000123")!,
                        title: "Design",
                        attendees: [
                            Attendee(id: Attendee.ID(UUID(2)), name: "")
                        ], meetings: []
                    )
                ]
            }
        }
    }
}
