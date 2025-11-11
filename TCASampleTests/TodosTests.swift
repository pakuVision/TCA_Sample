//
//  TodosTests.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/09.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import TCASample

@MainActor
struct TodosTests {
    
    let clock = TestClock()
    
    // Add 버튼을 두 번 눌렀을 때, Todo가 올바른 순서로 추가되는지를 검증
    @Test
    func testAddTodo() async {
        // 1. Test Store생성
        let store = TestStore(initialState: Todos.State()) {
            Todos()
        } withDependencies: { dependencies in
            // 2. 테스트용 uuid주입 (예측 가능하게)
            dependencies.uuid = .incrementing
        }
        
        // uuid 0인 Todo가 배열의 0번째 위치에 추가됨
        await store.send(.addTodoButtonTapped) { state in
            state.todos.insert(Todo.State(id: UUID(0), description: "", isComplete: false), at: 0)
        }
        
        // 두번째 add가 눌렸을 때
        // insert를 사용하므로 두번째 uuid 1 이 배열0 위치에 있고, uuid 0의 todo는 배열1에 위치하게 된다.
        await store.send(.addTodoButtonTapped) { state in
            state.todos = [
                Todo.State(id: UUID(1), description: "", isComplete: false),
                Todo.State(id: UUID(0), description: "", isComplete: false)
            ]
        }
    }
    
    @Test
    func testComplete() async {
        // todo 완료 체크하면 1초 후 완료된 항목이 맨 아래로 이동하는지 확인
        let state = Todos.State(todos: [
            Todo.State(id: .init(0), description: "", isComplete: false),
            Todo.State(id: .init(1), description: "", isComplete: false)
        ])
        
        let store = TestStore(initialState: state) {
            Todos()
        } withDependencies: { dependencies in
            dependencies.continuousClock = clock // 테스트용 가짝 시계 주입
            // clock : 실제 시간이 흐르지 않고 수동으로 시간을 조작할 수 있는 가짜시계
        }
        
        // - store.send(...) : 이 액션을 보낸다
        // - \.todos[id: UUID(0)].binding.isComplete : id가 0인 Todo의 isComplete를 바인딩
        // - true : true로 변경
        await store.send(\.todos[id: UUID(0)].binding.isComplete, true) { state in
            
            // 그러면 state가 이렇게 변할것이다. (예상값을 작성)
            state.todos[id: UUID(0)]?.isComplete = true
        }
        
        // 실제로 1초를 기다리지 않고 가짜시계로 1초 앞으로 돌림
        await clock.advance(by: .seconds(1))
        
        // 정령 액션 확인
        // store.receive(...) : 이 액션이 자동으로 발생할 것이다
        // \.sortCompletedTodos : 정렬 액션
        await store.receive(\.sortCompletedTodos) { state in
            // 그러면 state는 이렇게 변할 것이다. (예상값을 작성)
            state.todos = [
                state.todos[1],
                state.todos[0]
            ]
        }
        
    }
}
