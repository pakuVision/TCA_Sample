//
//  Todo.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/08.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Todo {
    
    @ObservableState
    struct State: Equatable, Identifiable {
        let id: UUID
        var description = ""
        var isComplete = false
    }
    
    enum Action: BindableAction {
        // 이 케이스를 자동 처리
        case binding(BindingAction<State>)
    }
    
    var body: some Reducer<State, Action> {
        // .binding 액션을 자동으로 State에 반영
        // 즉 이게 없으면  Reduce { state, action in .... 으로 일일이 case나열을 해야하지만
        // 특정 case에 별도의 추가 로직 (예: 로그삽입, 서버동기등.) 이 필요 없는 경우는
        // BindingReducer()를 호출하므로서 자동으로 레듀서를 바인딩 해줌
        BindingReducer()
    }
}

struct TodoView: View {
    
    @Bindable var store: StoreOf<Todo>
    var body: some View {
        HStack {
            Button {
                store.isComplete.toggle()
            } label: {
                Image(systemName: store.isComplete ? "checkmark.square" : "square")
            }
            .buttonStyle(.plain)
            
            TextField("Todo", text: $store.description)
        }
        .foregroundColor(store.isComplete ? .gray : nil)
    }
}
