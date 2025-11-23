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
    
    var theme: Theme = .bubblegum
}

struct Attendee: Equatable, Identifiable, Codable {
    let id: UUID
    var name = ""
}

enum Theme: String, CaseIterable, Equatable, Identifiable, Codable {
    case bubblegum
    case buttercup
    case indigo
    case lavender
    case magenta
    case navy
    case orange
    case oxblood
    case periwinkle
    case poppy
    case purple
    case seafoam
    case sky
    case tan
    case teal
    case yellow
    
    var id: Self { self }
    
    var textColor: Color {
        mainColor.isDarkColor ? .white : .black
    }
    
    var accentColor: Color {
        switch self {
        case .bubblegum, .buttercup, .lavender, .orange, .periwinkle, .poppy, .seafoam, .sky, .tan,
                .teal, .yellow:
            return .black
        case .indigo, .magenta, .navy, .oxblood, .purple:
            return .white
        }
    }
    
    var mainColor: Color { Color(rawValue) }
    var name: String { rawValue.capitalized }
}

extension Color {
    /// UIColor로 변환해서 밝기를 계산
    var isDarkColor: Bool {
        let uiColor = UIColor(self)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        // ITU-R BT.709에 따른 밝기 계산 공식
        let luminance = (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
        
        return luminance < 0.5   // 0.5 기준으로 어두우면 white를 선택
    }
}
