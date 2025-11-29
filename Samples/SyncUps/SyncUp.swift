//
//  SyncUpFeature.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SyncUpFeature {
    
    @Reducer
    enum Path {
        case detail(SyncUpDetail)
        case meeting(Meeting, syncUp: SyncUp)
        case record(RecordMeeting)
    }
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var syncUpsList = SyncUpsList.State()
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        case syncUpsList(SyncUpsList.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.syncUpsList, action: \.syncUpsList) {
            SyncUpsList()
        }
        
        Reduce { state, action in
            switch action {
                
            // detail의 Action을 여기에서 실행가능
            case let .path(.element(_, action: .detail(.delegate(delegateAction)))):
                switch delegateAction {
                case let .startMeeting(sharedSyncUp):
                    state.path.append(.record(RecordMeeting.State(syncUp: sharedSyncUp)) )
                }
                return .none
            case .path:
                return .none
            case .syncUpsList:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension SyncUpFeature.Path.State: Equatable {}

struct SyncUpView: View {
    @Bindable var store: StoreOf<SyncUpFeature>
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            SyncUpsListView(store: store.scope(state: \.syncUpsList, action: \.syncUpsList))
        } destination: { store in
            switch store.case {
            case let .detail(store):
                SyncUpDetailView(store: store)
            case .meeting:
                Text("MeetView")
            case let .record(store):
                RecordMeetingView(store: store)
            }
        }
    }
}

