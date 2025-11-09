import ComposableArchitecture
import SwiftUI

@Reducer
struct CounterFeature {
    
    @ObservableState
    struct State: Equatable {
        var count = 0
    }
    
    enum Action {
        case incrementButtonTapped
        case decrementButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return Effect.none
            case .decrementButtonTapped:
                state.count -= 1
                return Effect.none
            }
        }
    }
}

struct CounterView: View {
    let store: StoreOf<CounterFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(store.count)")
                .font(.system(size: 80).bold())
            
            HStack {
                Button("-") {
                    store.send(.decrementButtonTapped)
                }
                
                Button("+") {
                    store.send(.incrementButtonTapped)
                }
            }
        }
    }
}
