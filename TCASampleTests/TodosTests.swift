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
}
