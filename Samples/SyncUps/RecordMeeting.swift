//
//  RecordMeeting.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/25.
//

import ComposableArchitecture
import Speech
import SwiftUI
import Tagged
@Reducer
struct RecordMeeting {
    
    @ObservableState
    struct State: Equatable {
        
        @Presents var alert: AlertState<Action.Alert>?
        var secondElapsed = 0
        var speakerIndex = 0
        @Shared var syncUp: SyncUp
        var transcript = ""
        
        var durationRemaining: Duration {
            syncUp.duration - Duration.seconds(secondElapsed)
        }
    }
    
    enum Action {
        case alert(PresentationAction<Alert>)
        case endMeetingButtonTapped
        case nextButtonTapped
        case onTask

        // record
        case timerTick
        case speechResult(SpeechRecognitionResult)
        case speechFailure
        
        enum Alert {
            case confirmDiscard
            case confirmSave
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.speechClient) var speechClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmDiscard)):
                return .run { _ in
                    await dismiss()
                }
            case .alert(.presented(.confirmSave)):
                print("alert confirmSave!!")
                
                state.$syncUp.withLock { syncUp in
                    syncUp.insert(transcript: state.transcript)
                }
                
                return .run { _ in
                    await dismiss()
                }
            case .alert:
                return .none
            case .endMeetingButtonTapped:
                print("endMeetingButtonTapped!")
                // AlertState Type을 생성해서 대입 (얼럿뷰의 내용들을 스테이트로 관리)
                // AlertState로서 얼럿뷰를 표시
                state.alert = .endMeeting(isDiscardable: true)
                return .none
            case .nextButtonTapped:
                // 다음사람으로 레코딩 시작
                // 다음 사람이 없으면 얼럿을 표시
                guard state.speakerIndex < state.syncUp.attendees.count - 1 else {
                    state.alert = .endMeeting(isDiscardable: true)
                    return .none
                }
                
                state.speakerIndex += 1
                let durationPerAttendee: Duration = state.syncUp.duration / state.syncUp.attendees.count
                state.secondElapsed = state.speakerIndex * Int(durationPerAttendee.components.seconds)
                return .none
            case .onTask:
                print("onTask")
                return .run { send in
                    let authrization = await speechClient.authorizationStatus() == .notDetermined
                    ? speechClient.requestAuthorization()
                    : speechClient.authorizationStatus()
                    print("authrization status!: \(authrization)")
                    
                    await withDiscardingTaskGroup { group in
                        if authrization == .authorized {
                            group.addTask {
                                await startSpeechRecognition(send: send)
                            }
                        }
                        
                        group.addTask {
                            
                        }
                    }
                }

            case .timerTick:
                return .none
                
            case let .speechResult(result):
                state.transcript = result.bestTranscription.formattedString
                return .none
                
            case .speechFailure:
                if !state.transcript.isEmpty {
                    state.transcript += " ❌"
                }
                // alert을 표시
                state.alert = .speechRecognizerFailed
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    private func startSpeechRecognition(send: Send<Action>) async {
        print("startSpeechRecognition!!")
        do {
            let speechTask = await speechClient.startTask(request: UncheckedSendable(SFSpeechAudioBufferRecognitionRequest()))
            
            for try await result in speechTask {
                print("speechTask result!!: \(result)")
                 send(.speechResult(result))
            }
        } catch {
             send(.speechFailure)
        }
    }
}

struct RecordMeetingView: View {
    @Bindable var store: StoreOf<RecordMeeting>
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(store.syncUp.theme.mainColor)
            
            VStack {
                MeetingHeaderView(
                    secondElapsed: store.secondElapsed,
                    durationRemaining: store.durationRemaining,
                    theme: .bubblegum
                )
                
                MeetingTimerView(
                    syncUp: store.syncUp,
                    speakerIndex: store.speakerIndex
                )
                
                MeetingFooterView(
                    syncUp: store.syncUp,
                    nextButtonTapped: { store.send(.nextButtonTapped) },
                    speakerIndex: store.speakerIndex
                )
            }
        }
        .padding()
        .foregroundStyle(store.syncUp.theme.accentColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(id: "left", placement: .cancellationAction) {
                Button("End meeting") {
                    store.send(.endMeetingButtonTapped)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .alert($store.scope(state: \.alert, action: \.alert))
        .task {
            await store.send(.onTask).finish()
        }
    }
}

// AlertView에 표시할 내용을 여기에 선언 action이 RecordMeeting.Action.Alert일때만
extension AlertState where Action == RecordMeeting.Action.Alert {
    static func endMeeting(isDiscardable: Bool) -> Self {
        Self {
            TextState("End meeting?")
        } actions: {
            ButtonState(action: .confirmSave, label: {
                TextState("Save and end")
            })
            
            if isDiscardable {
                // discard버튼 눌러서 .confirmDiscard를 action
                ButtonState(role: .destructive, action: .confirmDiscard) {
                    TextState("Discard")
                }
            }
            
            ButtonState(role: .cancel) {
                TextState("Resume")
            }
        } message: {
            TextState("You are ending the meeing early. What would you like to do?")
        }
    }
    
    static var speechRecognizerFailed: Self {
        Self {
            TextState("Speech recognition failure")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("Continue meeting")
            }
            ButtonState(role: .destructive, action: .confirmDiscard) {
                TextState(
                    """
                    The speech recognizer has failed for some reason and so your meeting will no longer be \
                    recorded. What do you want to do?
                    """
                )
            }
        }
    }
}


struct MeetingTimerView: View {
    let syncUp: SyncUp
    let speakerIndex: Int
    
    var body: some View {
        Circle()
            .strokeBorder(lineWidth: 24)
            .overlay {
                VStack {
                    Group {
                        // 말하는 사람의 이름을 표시
                        if speakerIndex < syncUp.attendees.count {
                            let name = syncUp.attendees[speakerIndex].name
                            Text(name.isEmpty ? "Someone" : name)
                        } else {
                            Text("Someone")
                        }
                    }
                    .font(.title)
                    
                    Text("is speaking")
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .padding(.top)
                }
                .foregroundStyle(syncUp.theme.textColor)
            }
            .overlay {
                ForEach(syncUp.attendees.enumerated(), id:\.element.id) { index, attendee in
                    if index < speakerIndex + 1 {
                        SpeakerArc(totalSpeakers: syncUp.attendees.count, speakerIndex: index)
                            .rotation(.degrees(-90))
                            .stroke(syncUp.theme.mainColor, lineWidth: 12)
                    }
                }
            }
            .padding()
    }
}

struct SpeakerArc: Shape {
  let totalSpeakers: Int
  let speakerIndex: Int

  func path(in rect: CGRect) -> Path {
    let diameter = min(rect.size.width, rect.size.height) - 24
    let radius = diameter / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)
    return Path { path in
      path.addArc(
        center: center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: false
      )
    }
  }

  nonisolated private var degreesPerSpeaker: Double {
    360 / Double(totalSpeakers)
  }
  nonisolated private var startAngle: Angle {
    Angle(degrees: degreesPerSpeaker * Double(speakerIndex) + 1)
  }
  nonisolated private var endAngle: Angle {
    Angle(degrees: startAngle.degrees + degreesPerSpeaker - 1)
  }
}

struct MeetingFooterView: View {
    let syncUp: SyncUp
    var nextButtonTapped: () -> Void
    let speakerIndex: Int
    
    var body: some View {
        VStack {
            HStack {
                if speakerIndex < syncUp.attendees.count - 1 {
                    Text("Speaker \(speakerIndex + 1) of \(syncUp.attendees.count)")
                } else {
                    Text("No more Speakers")
                }
                Spacer()
                Button(action: nextButtonTapped) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("Next person")
                    }
                }
            }
        }
        .padding([.bottom, .horizontal])
    }
}


struct MeetingHeaderView: View {
    let secondElapsed: Int
    let durationRemaining: Duration
    let theme: Theme
    
    private var totalDuration: Duration {
        .seconds(secondElapsed) + durationRemaining
    }
    private var progress: Double {
        guard totalDuration > .seconds(0) else { return 0 }
        return Double(secondElapsed) / Double(totalDuration.components.seconds)
    }
    
    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(MeetingProgressViewStyle(theme: theme))
                .frame(height: 20)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Time Elapsed")
                        .font(.caption)
                    
                    Label(
                        Duration.seconds(secondElapsed).formatted(.units()),
                        systemImage: "hourglass.bottomhalf.fill"
                    )
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Time Remaining")
                        .font(.caption)
                    Label(durationRemaining.formatted(.units()), systemImage: "hourglass.bottomhalf.fill")
                        .font(.body.monospacedDigit())
                }
            }
        }
        .padding([.top, .horizontal])
    }
}

struct MeetingProgressViewStyle: ProgressViewStyle {
    var theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.accentColor)
            
            ProgressView(configuration)
                .tint(theme.mainColor)
                .frame(height: 12)
                .padding(.horizontal)
        }
    }
}

extension SyncUp {
    fileprivate mutating func insert(transcript: String) {
        
        @Dependency(\.date.now) var now
        @Dependency(\.uuid) var uuid
        
        let newMeeting = Meeting(id: Meeting.ID(uuid()), date: now, transcript: transcript)
        meetings.insert(newMeeting, at: 0)
    }
}
