//
//  Models.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/16.
//

import IdentifiedCollections
import SwiftUI
import Tagged

struct SyncUp: Equatable, Identifiable, Codable {
    let id: Tagged<Self, UUID>
    var attendees: IdentifiedArrayOf<Attendee>
}

struct Attendee: Equatable, Identifiable, Codable {
    let id: Tagged<Self, UUID>
    var name = ""
}


