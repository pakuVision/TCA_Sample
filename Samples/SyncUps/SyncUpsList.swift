//
//  SyncUpsList.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import ComposableArchitecture
import SwiftUI
import Tagged

@Reducer
struct SyncUpsList {
    
    @Reducer
    enum Destination {
        case add(SyncUpForm)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        // 프로퍼티래퍼
        // 여러 Feature간에 상태를 공유할 때 사용 (Static .shared와 비슷하지만 Observable기능임)
        // .syncUps라는 custom KEY를 사용해서 공유 상태를 선언
        // 하나의 저장소(key)에 저장된 상태를 여러 레듀서에서 동일하게 보게 하는 기능
        @Shared(.syncUps) var syncUps
    }
    
    enum Action {
        case addSyncUpButtonTapped
        case onDelete(IndexSet)
        case confirmAddSyncUpButtonTapped
        case dismissAddSheetButtonTapped
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Dependency(\.uuid) var uuid
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            
            switch action {
            case .addSyncUpButtonTapped:
                state.destination = .add(
                    SyncUpForm.State(syncUp: SyncUp(id: SyncUp.ID(uuid()), attendees: [], meetings: []))
                )
                return .none
            case let .onDelete(indexSet):
                state.$syncUps.withLock { $0.remove(atOffsets: indexSet) }
                return .none
                
            case .confirmAddSyncUpButtonTapped:
                guard case let .some(.add(editState)) = state.destination else { return .none }
                var newSyncUp = editState.syncUp
                
                newSyncUp.attendees.removeAll { attendee in
                    attendee.name.allSatisfy(\.isWhitespace)
                }
                
                if newSyncUp.attendees.isEmpty {
                    newSyncUp.attendees.append(Attendee(id: Attendee.ID(uuid())))
                }
                
                state.$syncUps.withLock { _ = $0.append(newSyncUp) }
                
                state.destination = nil
                
                return .none
                
            case .dismissAddSheetButtonTapped:
                state.destination = nil
                return .none
            
            case .destination:
                return .none
            }
        }
        // 옵셔널 State (@Presents)와 해당 액션을 연결(scope) 할 때 사용
        // 옵셔널한 하위 Feature(sheet, NavigationDestination. Alert)등을 사용할때 반드시 사용하는 패턴
        // ifLet으로 nil이 아닐때만 하위 Reducer를 실행하도록 Scoping
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SyncUpsList.Destination.State: Equatable {}


struct SyncUpsListView: View {
    
    @Bindable var store: StoreOf<SyncUpsList>
    
    var body: some View {
        List {
            ForEach(Array(store.$syncUps)) { $syncup in
                
                // TCA용 NavigationLink 래퍼
                // @Shared syncups의 각 요소를 하위Feature에서 @Shared로서 바인딩
                // SyncUpFeature.Path .State 라는 타입이 자동으로 생성되는 이유는 Path가 @Reducer로 선언된 Feature이기 때문
                // @Reducer로 선언된 enum은 자동으로 .State .Action타입을 생성한다.
                
                // 여기서 detail로 천이하기 위해서는 상위Feature Path의 detail.State를 설정해야 한다.
                // SyncUpFeature.Path.State.detail(...)
                let state = SyncUpFeature.Path.State.detail(SyncUpDetail.State(syncUp: $syncup))
                NavigationLink(state: state) {
                    // Label
                    CardView(syncUp: syncup)
                }
                .listRowBackground(syncup.theme.mainColor)
            }
            .onDelete { indexSet in
                store.send(.onDelete(indexSet))
            }
        }
        .toolbar {
            Button {
                store.send(.addSyncUpButtonTapped)
            } label: {
                Image(systemName: "plus")
            }
        }
        .navigationTitle("Daily Sync-ups")
        .sheet(item: $store.scope(state: \.destination?.add, action: \.destination.add)) { formStore in
            NavigationStack {
                SyncUpFormView(store: formStore)
                    .navigationTitle("New sync-up")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Dismiss") {
                                self.store.send(.dismissAddSheetButtonTapped)
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                store.send(.confirmAddSyncUpButtonTapped)
                            }
                        }
                    }
            }
        }
    }
}

struct CardView: View {
    let syncUp: SyncUp
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(syncUp.title)
                .font(.headline)
            Spacer()
            HStack {
                Label("\(syncUp.attendees.count)", systemImage: "person.3")
                Spacer()
                Label(syncUp.duration.formatted(.units()), systemImage: "clock")
            }
            .font(.caption)
        }
        .padding()
        .foregroundStyle(syncUp.theme.textColor)
    }
}


extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<SyncUp>>.Default {
    
    // .syncUps라는 키를 새로 정의
    // 타입: FileStorageKey<IdenfiedArrayOf<SyncUp>>.Default
    // 저장위치: Documents/sync-ups.json
    // default: 기본값은 빈배열
    // -> syncUps라는 공유 저장소를 하나 만들겠다 - 라고 선언
    static var syncUps: Self {
        Self[.fileStorage(.documentsDirectory.appending(component: "sync-ups.json")), default: []]
    }
}
