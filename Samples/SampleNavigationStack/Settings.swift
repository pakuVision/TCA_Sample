//
//  Settings.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/17.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Settings {
    
    @ObservableState
    struct State: Equatable {
        var username = ""
        var notificationsEnabled = true
        var darkModeEnabled = false
    }
    
    enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case usernameChanged(String)
        case saveButtonTapped
        case resetButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
            case let .usernameChanged(name):
                state.username = name
                return .none
                
            case .saveButtonTapped:
                print("Settings saved: \(state.username)")
                return .none
                
            case .resetButtonTapped:
                state.username = ""
                state.notificationsEnabled = true
                state.darkModeEnabled = false
                return .none
            case .binding:
                return .none
            }
        }
    }
}

struct SettingsView: View {
    @Bindable var store: StoreOf<Settings>
    
    var body: some View {
        Form {
            Section("Account") {
                TextField("Username", text: $store.username)
                
                HStack {
                    Text("Current:")
                    Spacer()
                    Text(store.username.isEmpty ? "Not Set" : store.username)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Preferences") {
                Toggle("Enable Notifications", isOn: $store.notificationsEnabled)
                Toggle("Dark Mode", isOn: $store.darkModeEnabled)
                
            }
            
            Section {
                Button("Save Settings") {
                    store.send(.saveButtonTapped)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.blue)
                
                Button("Reset to Defaults") {
                    store.send(.resetButtonTapped)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

