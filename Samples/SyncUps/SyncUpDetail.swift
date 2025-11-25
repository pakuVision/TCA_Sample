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
        case startMeetingButtonTapped
        case cancelEditButtonTapped
        case deleteButtonTapped
        case editButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .startMeetingButtonTapped:
                return .none
            case .cancelEditButtonTapped:
                return .none
            case .editButtonTapped:
                return .none
            case .deleteButtonTapped:
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
            infoSectionView
            attendeesSectionView
        }
        .toolbar {
            Button("Edit") {
                store.send(.editButtonTapped)
            }
        }
    }
    
    private var infoSectionView: some View {
        Section {
            Button {
                store.send(.startMeetingButtonTapped)
            } label: {
                Label("Start Meeting", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
            HStack {
                Label("Theme", systemImage: "paintpalette")
                Spacer()
                Text(store.syncUp.theme.name)
                    .padding(4)
                    .foregroundStyle(store.syncUp.theme.textColor)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .fill(store.syncUp.theme.mainColor)
                    )
            }
        } header: {
            Text("Sync-up Info")
        }
    }
    
    private var meetingSectionView: some View {
        Section {
            ForEach(store.syncUp.meetings) { meeting in
                NavigationLink(
                    state: SyncUpFeature.Path.State.meeting(meeting, syncUp: store.syncUp)
                ) {
                    HStack {
                        Image(systemName: "calender")
                        Text(meeting.date, style: .date)
                        Text(meeting.date, style: .time)
                    }
                }
            }
        } header: {
            Text("Past meeting")
        }
    }
    
    private var attendeesSectionView: some View {
        Section {
            ForEach(store.syncUp.attendees) { attendee in
                Label(attendee.name, systemImage: "person")
            }
        } header: {
            Text("Attendees")
        }
    }
    
    private var deleteSectionView: some View {
        Section {
            Button("Delete") {
                store.send(.deleteButtonTapped)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
        }
    }
}
