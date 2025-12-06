//
//  OpenSettings.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/06.
//

import Dependencies
import UIKit

// openSetting이라는 기능을 주입하기 위해 만든 커스텀 Dependency 정의이다.
// 굳이 이것을 Dependency로 만든 가장 큰 이유는
// 테스트 가능성 + 동작의 추상화  때문

extension DependencyValues {
    var openSettings: @Sendable () async -> Void {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
    
    private enum OpenSettingsKey: DependencyKey {
        typealias Value = @Sendable () async -> Void
        
        static let liveValue: @Sendable () async -> Void = {
            await MainActor.run {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
    }
}
