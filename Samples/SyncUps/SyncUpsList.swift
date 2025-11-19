//
//  SyncUpsList.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SyncUpsList {
    
    @Reducer
    enum Destination {
        case add
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        // 여러 Feature간에 상태를 공유할 때 사용 (Static .shared와 비슷하지만 Observable기능임)
        // .syncUps라는 custom KEY를 사용해서 공유 상태를 선언
      //  @Shared(.syncUps) var syncUps: [SyncUp] = []
    }
    
    enum Action {
        case addSyncUpButtonTapped
    }
    
    @Dependency(\.uuid) var uuid
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            
            switch action {
            case .addSyncUpButtonTapped:
                print("addSyncUpButtonTapped!!")
                return .none
            }
        }
    }
}

extension SyncUpsList.Destination.State: Equatable {}


struct SyncUpsListView: View {
    
    @Bindable var store: StoreOf<SyncUpsList>
    
    var body: some View {
        List {
            
        }
        .toolbar {
            Button {
                store.send(.addSyncUpButtonTapped)
            } label: {
                Image(systemName: "plus")
            }
        }
        .navigationTitle("Daily Sync-ups")
    }
}

extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<SyncUp>>.Default {
    static var syncUps: Self {
        Self[.fileStorage(.documentsDirectory.appending(component: "sync-ups.json")), default: []]
    }
}
