//
//  SyncUpDetail.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.


import ComposableArchitecture
import SwiftUI

@Reducer
struct SyncUpDetail {
    
    @Reducer
    enum Destination {
       // case alert(AlertState<Alert>)
        case edit
        
//        enum Alert {
//            case confirmDeletion
//        }
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        @Shared var syncUp: SyncUp
    }
    
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case cancelEditButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .cancelEditButtonTapped:
                return .none
            }
        }
    }
    
}

extension SyncUpDetail.Destination.State: Equatable { }

struct SyncUpDetailView: View {
    @Bindable var store: StoreOf<SyncUpDetail>
    
    var body: some View {
        Form {
            Text("SyncUpDetailView")
        }
    }
}
