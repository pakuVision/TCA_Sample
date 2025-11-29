//
//  Meeting.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/25.
//

import SwiftUI

struct MeetingView: View {
    let meeting: Meeting
    let syncUp: SyncUp
    
    var body: some View {
        Form {
            Section {
                ForEach(syncUp.attendees) { attendee in
                    Text(attendee.name)
                }
            } header: {
                Text("Attendees")
            }
            
            Section {
                Text(meeting.transcript)
            } header: {
                Text("Transcript")
            }
        }
        .navigationTitle(Text(meeting.date, style: .date))
    }
}
