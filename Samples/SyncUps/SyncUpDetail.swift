//
//  SyncUpDetail.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.


import ComposableArchitecture
import SwiftUI
@preconcurrency import Speech

@Reducer
struct SyncUpDetail {
    
    @Reducer
    enum Destination {
        case alert(AlertState<Alert>)
        case edit(SyncUpForm)
        
        @CasePathable
        enum Alert {
            case confirmDeletion
            case continueWithoutRecording
            case openSettings
        }
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
        case delegate(Delegate)
        case cancelEditButtonTapped
        case deleteMeetings(_ indexSet: IndexSet)
        case deleteButtonTapped
        case editButtonTapped
        case doneEditingButtonTapped
    }
    
    @CasePathable
    enum Delegate {
        case startMeeting(Shared<SyncUp>)
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.openSettings) var openSettings
    @Dependency(\.speechClient.authorizationStatus) var authorizationStatus
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startMeetingButtonTapped:
                print("startMeetingButtonTapped")
                switch authorizationStatus() {
                case .authorized, .notDetermined:
                    return .send(.delegate(Delegate.startMeeting(state.$syncUp)))
                case .denied:
                    print("denied")
                    state.destination = .alert(.speechRecognitionDenied)
                    return .none
                case .restricted:
                    state.destination = .alert(.speechRecognitionRestricted)
                    return .none
                    
                @unknown default:
                    return .none
                }
            case let .deleteMeetings(indexSet):
                state.$syncUp.withLock { syncUp in
                    syncUp.meetings.remove(atOffsets: indexSet)
                }
                return .none
            case .cancelEditButtonTapped:
                return .none
            case .editButtonTapped:
                state.destination = .edit(SyncUpForm.State(syncUp: state.syncUp))
                return .none
            case .doneEditingButtonTapped:
                // destination에 잇는 변경된 syncUps을 취득해서
                // detail이 가지고 있는 state.$syncUp에 악세스해서 변경된 녀석으로 바꿔치기한다.
                // 그리고 state.destination = nil 을 하므로서 sheet이 close된다.
                guard case let .some(.edit(editState)) = state.destination else { return .none }
                state.$syncUp.withLock {
                    $0 = editState.syncUp
                }
                state.destination = nil
                return .none
            case let .destination(.presented(.alert(alertAction))):
                switch alertAction {
                case .openSettings:
                    return .run { send in
                        await openSettings()
                    }
                case .continueWithoutRecording:
                    return .send(.delegate(.startMeeting(state.$syncUp)))
                case .confirmDeletion:
                    @Shared(.syncUps) var syncUps
                    $syncUps.withLock { syncUps in
                      _ = syncUps.remove(id: state.syncUp.id)
                    }
                    return .run { send in
                        await dismiss()
                    }
                }
            case .deleteButtonTapped:
                state.destination = .alert(.deleteSyncUp)
                return .none
            case .delegate:
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SyncUpDetail.Destination.State: Equatable { }

struct SyncUpDetailView: View {
    @Bindable var store: StoreOf<SyncUpDetail>
    
    var body: some View {
        Form {
            infoSectionView
            if !store.syncUp.meetings.isEmpty {
                meetingSectionView
            }
            attendeesSectionView
            deleteSectionView
        }
        .toolbar {
            Button("Edit") {
                store.send(.editButtonTapped)
            }
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .sheet(item: $store.scope(state: \.destination?.edit, action: \.destination.edit)) { formStore in
            NavigationStack {
                SyncUpFormView(store: formStore)
                    .navigationTitle(store.syncUp.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                store.send(.cancelEditButtonTapped)
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                store.send(.doneEditingButtonTapped)
                            }
                        }
                    }
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
                Label("Length", systemImage: "clock")
                Spacer()
                Text(store.syncUp.duration.formatted(.units()))
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
                        Image(systemName: "calendar")
                        Text(meeting.date, style: .date)
                        Text(meeting.date, style: .time)
                    }
                }
            }
            .onDelete { indexSet in
                store.send(.deleteMeetings(indexSet))
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

extension AlertState where Action == SyncUpDetail.Destination.Alert {
    static let deleteSyncUp = Self {
        TextState("Delete?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("Yes")
        }
        ButtonState(role: .cancel) {
            TextState("Nevermind")
        }
    }
    
    static let speechRecognitionDenied = AlertState {
        TextState("Speech recognition denied")
    } actions: {
        ButtonState(action: .continueWithoutRecording) {
            TextState("Continue without recorning")
        }
        
        ButtonState(action: .openSettings) {
            TextState("Open settings")
        }
        
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    }
    
    static let speechRecognitionRestricted = Self {
      TextState("Speech recognition restricted")
    } actions: {
      ButtonState(action: .continueWithoutRecording) {
        TextState("Continue without recording")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    } message: {
      TextState(
        """
        Your device does not support speech recognition and so your meeting will not be recorded.
        """
      )
    }
}
