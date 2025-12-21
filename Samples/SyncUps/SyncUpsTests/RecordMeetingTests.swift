//
//  RecordMeetingTests.swift
//  TCASampleTests
//
//  Created by boardguy.vision on 2025/12/18.
//

import ComposableArchitecture
import Testing
import Tagged
import Foundation
@testable import TCASample
internal import Speech

@MainActor
struct RecordMeetingTests {
    
    init() { uncheckedUseMainSerialExecutor = true }
    
    @Test
    func timer() async {
        let clock = TestClock()
        
        let store = TestStore(
            initialState: RecordMeeting.State(
                syncUp: Shared(
                    value: SyncUp(
                        id: SyncUp.ID(),
                        duration: .seconds(6),
                        attendees: [
                            Attendee(id: Attendee.ID(), name: "A"),
                            Attendee(id: Attendee.ID(), name: "B"),
                            Attendee(id: Attendee.ID(), name: "C")
                        ]
                    )
                )
            )
        ) {
            RecordMeeting()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.continuousClock = clock
            $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
            $0.speechClient.authorizationStatus = { .denied }
        }
        
        await store.send(.onTask)
        
        await clock.advance(by: .seconds(1))
        await store.receive(\.timerTick) {
            $0.speakerIndex = 0
            $0.secondElapsed = 1
            #expect($0.durationRemaining == .seconds(5))
        }
    }
    
    
}
