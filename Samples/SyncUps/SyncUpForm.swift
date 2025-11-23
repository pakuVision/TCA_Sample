//
//  SyncUpForm.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/22.
//

import ComposableArchitecture
import SwiftUI
import SwiftNavigation

@Reducer
struct SyncUpForm {
    
    @ObservableState
    struct State: Equatable {
        var focus: FocusField? = .title
        var syncUp: SyncUp
        
        init(syncUp: SyncUp) {
            self.syncUp = syncUp
            
            if self.syncUp.attendees.isEmpty {
                
                //DependencyValues안에 정의된 특정 의존성 키를 "참조하여" 가져오는 문법이며, (keyPath문법)
                // 테스트나 프리뷰. 실행 환경에서.  그 값을 밖에서 원하는 값으로 주입할 수 있게 하는 기능
                @Dependency(\.uuid) var uuid
                self.syncUp.attendees.append(Attendee(id: uuid()))
            }
        }
        
        nonisolated
        enum FocusField: Hashable, Sendable {
            case attendee(UUID)
            case title
        }
    }
    
    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case addAttendeeButtonTapped
        case deleteAttendee(indexSet: IndexSet)
        
    }
    
    @Dependency(\.uuid) var uuid
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
            case .addAttendeeButtonTapped:
                let uuid = self.uuid()
                let newAttendee = Attendee(id: uuid)
                state.syncUp.attendees.append(newAttendee)
                // 追加したAttendeeを focusさせる
                state.focus = .attendee(uuid)
                return .none
                
            case .binding:
                 return .none
                
            case let .deleteAttendee(indexSet):
                state.syncUp.attendees.remove(atOffsets: indexSet)
                return .none
            }
        }
    }
}

struct SyncUpFormView: View {
    @Bindable var store: StoreOf<SyncUpForm>
    @FocusState var focus: SyncUpForm.State.FocusField?
    
    var body: some View {
        Form {
            infoSectionView
            attendeeSectionView
        }
        .bind($store.focus, to: $focus)
    }
    
    private var infoSectionView: some View {
        Section {
            TextField("Title", text: $store.syncUp.title)
                .focused($focus, equals: .title)
            
            HStack {
                Slider(value: $store.syncUp.duration.minutes, in: 5...30, step: 1) {
                    Text("Length")
                }
                Spacer()
                Text(store.syncUp.duration.formatted(.units()))
            }
        } header: {
            Text("Sync-up Info")
        }
    }
    
    private var attendeeSectionView: some View {
        Section {
            ForEach($store.syncUp.attendees) { $attendee in
                TextField("Name", text: $attendee.name)
                    .focused($focus, equals: .attendee(attendee.id))
                
            }
            .onDelete { indexSet in
                store.send(.deleteAttendee(indexSet: indexSet))
            }
            
            Button("New attendee") {
                store.send(.addAttendeeButtonTapped)
            }
        } header: {
            Text("Attendees")
        }
    }
}

extension Duration {
    fileprivate var minutes: Double {
        get { Double(components.seconds / 60 )}
        set { self = .seconds(newValue * 60) }
    }
}
