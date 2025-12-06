//
//  SyncUpTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2025/12/06.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import TCASample
internal import SwiftUI

// mainActor == 무조건 단일 스레드 실행이라 오해하지만, 틀리다.
// 이것은 일관된 보호를 보장하지만 항상 한 스레드에서 직렬 실행된다 라는 보장은 없다.
// mainActor 실행기 (executor)는 상황에 따라 다른 스레드에 hop 할 수 있다.  (hop = 스레드이동)
// 그래서 아래의 한줄 코드를 실행하므로서  테스트를 한 스레드로 강제하는 것이다
@MainActor

struct SyncUpTests {
    init() {
        /*
         TCA테스트환경에서 Swift Concurrency의 메인액터 동작을 단일 직렬 실행기로 강제하기 위한 설정
         - 메인 액터에서 실행되는 모든 async 코드가 딱 한 스레드에서 순서대로 처리됨
         - 실행 순서가 100% 안정적
         */
        uncheckedUseMainSerialExecutor = true
    }
    
    @Test
    func testDetailEdit() async throws {
        let syncUp = SyncUp.mock
        @Shared(.syncUps) var syncUps = [syncUp]
        
        let store = TestStore(initialState: SyncUpFeature.State()) {
            SyncUpFeature()
        }
        
        // #require - 필수조건을 테스트 (Shared의 syncup데이터를 취득 + 언래핑) nil이면 테스트 실패
        let sharedSyncUp = try #require(Shared($syncUps[id: syncUp.id]))
        
        // 1. detail화면 푸시
        await store.send(\.path.push, (id: 0, .detail(SyncUpDetail.State(syncUp: sharedSyncUp)))) { state in
            // 여기에는 기댓값이 되도록 state를 갱신
            state.path[id: 0] = .detail(SyncUpDetail.State(syncUp: sharedSyncUp))
        }
        
        // 2. edit버튼 탭
    
        // path 0번째 화면이 detail상태일 때, 그 안의 editButtonTapped Action을 보낸다.
        await store.send(\.path[id: 0].detail.editButtonTapped) { state in
            
            // 0번째 화면이 detail일 때,
            // 그 detail의 destination 값을 edit상태로 바꾼다.
            
            // yield - inout State의 파라메터명
            // 즉 modify안에서 가지고 있는 내부값을 클로저 쪽으로 보내고 거기서 값을 변경하면 다시 그것을 내부로 반영되는 이미지
            state.path[id: 0].modify(\.detail, yield: {
                
                //destination은 detail이 가지고 있는 enum
                // case는 alert, edit
                // 여기에서 edit을 설정
                $0.destination = .edit(SyncUpForm.State(syncUp: syncUp))
            })
            
            // 아래는 위의 코드와 같은것임 아래처럼 if case로 추출해서 내부 값꺼내고... 같은 짓을 할필요 없이 .modify로 심플하게 값을 변경가능하게 함
//            if case .detail(var detailState) = state.path[id: 0] {
//                detailState.destination = .edit(SyncUpForm.State(syncUp: syncUp))
//                state.path[id: 0] = .detail(detailState)
//            }
            
            
        }
        
        var newSyncUp = syncUp
        newSyncUp.title = "Edited Title!"
        
        await store.send(\.path[id: 0].detail.destination.edit.binding.syncUp, newSyncUp) { state in
//            state.path[id: 0].modify(\.detail, yield: { detailState in
//                detailState.destination.modify(\.edit, yield: { editState in
//                    editState.syncUp.title = "Blob"
//                })
//            })
            
            // 위와 동일한 코드
            if case .detail(var detailState) = state.path[id: 0] {
                
                if case .edit(var editState) = detailState.destination {
                    editState.syncUp.title = "Edited Title!"
                    detailState.destination = .edit(editState)
                    
                    // 마지막으로 state에 기댓값을 대입
                    state.path[id: 0] = .detail(detailState)
                }
            }
        }
        
        // 마지막으로 done(save) 버튼이 눌렸을때의 테스트
        await store.send(\.path[id: 0].detail.doneEditingButtonTapped) { state in
            
            if case .detail(var detailState) = state.path[id: 0] {
                
                // destination == nil이 되어서 dismiss되야됨
                detailState.destination = nil
                
                // SharedState(syncUp)의 수정이 일어나야 함
                // $syncUp은 Shared Entry이며, SharedState는 thread-safe mutation을 위해 항상 .withLock {}을 사용해야한다
                detailState.$syncUp.withLock { $0.title = "Edited Title!" }
                
                // state에 기댓값을 반영
                state.path[id: 0] = .detail(detailState)
            }
        }
        // 테스트가 모든 Effect를 처리했고 더 이상 기다릴 작업이 없다는 것을 확인하는 단계
        // finish는
        // - 미처리된 Effect가 남아 있는지
        // - reducer가 비동기 작업을 아직 기다리고 있는지
        // - cancellation이 필요하지만 실행되지 않은 Effect가 있는지
        // - test schedular가 처리해야 할 이벤트가 남아 있는지
        // - navigation path의 effect와 shared state반영이 완전이 끝났는지
        // 이 모든것을 검사하요
        // 테스트를 완전히 끝내도 좋다라고 보증하는 역할
        .finish()
    }
}
