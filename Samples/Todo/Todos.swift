//
//  TodoFeature.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/08.
//

import ComposableArchitecture
import SwiftUI

enum Filter: LocalizedStringKey, CaseIterable, Hashable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
}

@Reducer
struct Todos {
    
    @ObservableState
    struct State: Equatable {
        var editMode: EditMode = .inactive
        var filter: Filter = .all
        var todos: IdentifiedArrayOf<Todo.State> = []
        
        var filteredTodos: IdentifiedArrayOf<Todo.State> {
            
            switch filter {
            case .active:
                return self.todos.filter { !$0.isComplete }
            case .all:
                return self.todos
            case .completed:
                return self.todos.filter(\.isComplete)
            }
        }
    }
    
    enum Action: BindableAction {
        case clearCompletedButtonTapped
        case addTodoButtonTapped
        case binding(BindingAction<State>)
        case sortCompletedTodos
        case todos(IdentifiedActionOf<Todo>)
        case delete(IndexSet)
        case move(IndexSet, Int)

    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .clearCompletedButtonTapped:
                state.todos.removeAll(where: { $0.isComplete })
                return .none
            case .addTodoButtonTapped:
                state.todos.insert(Todo.State(id: self.uuid()), at: 0)
                return .none
            case .binding:
                return .none
                
            // .todos의 액션중에서 .isComplete의 바인딩이 병경되었을 때의 조건시 여기가 호출됨
            // action case의 특정 조건이 일반보다 먼저 호출된다.
            case .todos(.element(id: _, action: .binding(\.isComplete))):
                return .run { send in
                    try await self.clock.sleep(for: .seconds(1))
                    await send(.sortCompletedTodos, animation: .default)
                }
            case .sortCompletedTodos:
                print("sortCompletedTodos!!!")
                // sort { $0, $1 in
                // true를  반환하면 $0이 $1보다 앞에 위치
                // false를 반환하면 $1이 $0보다 앞에 위치
                // 완료한 todo를 뒤쪽으로
                state.todos.sort { !$0.isComplete && $1.isComplete }
                return .none
            case .todos:
                // .todos의 특정 케이스에 매칭되지 않은 모든 나머지 todos 액션처리
                return .none
                
            case let .delete(indexSet):
                let filteredTodos = state.filteredTodos
                for index in indexSet {
                    let id = filteredTodos[index].id
                    state.todos.remove(id: id)
                }
                return .none
                
            case var .move(source, destination):
                
                // current tap이 completed인 경우 (완료 todos를 표시중일때)
                if state.filter == .completed {
                    
                    source = IndexSet(
                        source
                            .map { state.filteredTodos[$0] }
                            .compactMap { state.todos.index(id: $0.id )}
                    )
                    
                    destination = (destination < state.filteredTodos.endIndex ?
                              state.todos.index(id: state.filteredTodos[destination].id) : state.todos.endIndex) ?? destination
                }
                
                // drag and drop처리
                state.todos.move(fromOffsets: source, toOffset: destination)
                
                // 100ms 후 완료된 요소정렬
                return .run { send in
                    try await self.clock.sleep(for: .milliseconds(100))
                    await send(.sortCompletedTodos)
                }
            }
        }
        // 부모 Reducer가 자식 Reducer들을 관리하기 위한 TCA의 Composition 메커니즘이다.
        // 이 코드는 세 가지를 연결
        // 1. \.todos (State의 컬랙션
        // 2. \.todos (Action의 케이스)
        // 3. Todo() 자식 Reducer
        .forEach(\.todos, action: \.todos) {
            Todo()
        }
    }
}

struct TodosView: View {
    
    @Bindable var store: StoreOf<Todos>
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                Picker("Filter", selection: $store.filter.animation()) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                todosView
            }
            .navigationTitle("Todos")
            .toolbar(content: {
                HStack(spacing: 20) {
                    EditButton()
                    Button("Clear Completed") {
                        
                    }
                    Button("Add Todo") {
                        store.send(.addTodoButtonTapped, animation: .easeInOut)
                    }
                }
                .padding(.trailing)
            })
            // EditButton()을 store.editmode로 바인딩
            // list쪽에 .onDelete .onMove등을 추가
            .environment(\.editMode, $store.editMode)
        }
    }
    
    private var todosView: some View {
        List {
            // 부모(todos) Store에 있는
            // state: 대상 filteredTodos와 action: 대상 \.todos 를
            // ↓↓↓↓↓↓
            // 자식 (todo) Store 로 변환
            
            // ForEach가 하는일 - 각 Todo마다 독립적인 Store를 만들어서 TodoView에 전달
            
            ForEach(store.scope(state: \.filteredTodos, action: \.todos)) { store in
                TodoView(store: store)
            }
            .onDelete { store.send(.delete($0)) }
            .onMove { store.send(.move($0, $1)) }
        }
    }
}
