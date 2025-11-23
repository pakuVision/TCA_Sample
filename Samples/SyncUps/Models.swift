//
//  Models.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import IdentifiedCollections
import SwiftUI
import Tagged

nonisolated
struct SyncUp: Equatable, Identifiable, Codable {
    let id: UUID
    var title: String = ""
    var duration: Duration = .seconds(60 * 5) // 5分
    var attendees: IdentifiedArrayOf<Attendee> 
}

struct Attendee: Equatable, Identifiable, Codable {
    let id: UUID
    var name = ""
}


