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
        
        // 상위 Feature의 @Shared syncUps의 각 요소인 SyncUp을 하위Feature(여기) 에서 바인딩하기 위해서 @Shared 를 사용 (@Binding같은 개념)
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
