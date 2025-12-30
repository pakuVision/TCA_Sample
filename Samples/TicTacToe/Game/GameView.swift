//
//  GameView.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/28.
//

import ComposableArchitecture
import SwiftUI

struct GameView: View {
    
    @Bindable var store: StoreOf<Game>
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                VStack {
                    Text(store.title)
                    
                    if store.isPlayAgainButtonVisible {
                        Button("Play again?") {
                            store.send(.playAgainButtonTapped)
                        }
                        .padding(.top)
                    }
                }
                .font(.title)
                .padding(.top)
                .frame(maxHeight: .infinity, alignment: .center)
                
                Spacer()
                VStack {
                    rowView(row: 0, proxy: proxy)
                    rowView(row: 1, proxy: proxy)
                    rowView(row: 2, proxy: proxy)
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("Tic-tac-toe")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Quit") {
                        store.send(.quitButtonTapped)
                    }
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
    
    func rowView(row: Int, proxy: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            let width = proxy.size.width / 3

            cellView(row: row, column: 0, size: .init(width: width, height: width))
            cellView(row: row, column: 1, size: .init(width: width, height: width))
            cellView(row: row, column: 2, size: .init(width: width, height: width))
        }
    }
    
    func cellView(row: Int, column: Int, size: CGSize) -> some View {
        Button {
            store.send(.cellTapped(row: row, column: column))
        } label: {
            Text(store.rows[row][column])
                .frame(width: size.width, height: size.height)
                .background( // 2로 나누어떨어지는지 아닌지.
                    ((row + column).isMultiple(of: 2) ? Color.gray : Color.blue).opacity(0.3)
                )
        }
    }
    
}

extension Game.State {
    fileprivate var title: String {
        self.board.hasWinner ? "Winner! \(self.currentPlayer.label)" : self.board.isFilled ? "Tied!" : "place your \(self.currentPlayer.label)"
    }
    
    fileprivate var isPlayAgainButtonVisible: Bool {
        self.board.hasWinner || self.board.isFilled
    }
    
    fileprivate var rows: [[String]] {
        self.board.map { $0.map { $0?.label ?? "" }}
    }
}

