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
       // var focus: Field? = .title
        var syncUp: SyncUp
        
        init(syncUp: SyncUp) {
            self.syncUp = syncUp
        }
    }
    
    enum Field: Hashable {
     //   case attendee(Attendee.ID)
        case title
    }
    
    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case addAttendeeButtonTapped
        
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
            case .addAttendeeButtonTapped:
                return .none
                
            case .binding:
                 return .none
            }
        }
    }
}

struct SyncUpFormView: View {
    @Bindable var store: StoreOf<SyncUpForm>
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $store.syncUp.title)
                
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
    }
}

extension Duration {
    fileprivate var minutes: Double {
        get { Double(components.seconds / 60 )}
        set { self = .seconds(newValue * 60) }
    }
}
