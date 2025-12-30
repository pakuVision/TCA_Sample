//
//  Three.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/12/28.
//

public struct Three<Element> {
    public var first: Element
    public var second: Element
    public var third: Element
    
    public init(_ first: Element, _ second: Element, _ third: Element) {
        self.first = first
        self.second = second
        self.third = third
    }
    
    // .map Element타입이 T타입으로 변환
    // transforom: 함수 (Element) -> T
    // .map { 여기내용 }
    // .map { $0 <- Element
    // .map {  return T } : T - 변환된 타입
    public func map<T>(_ transform: (Element) -> T) -> Three<T> {
        .init(
            transform(self.first),
            transform(self.second),
            transform(self.third)
        )
    }
}

// Element가 Equatable일 때만 Three도 Equatable
extension Three: Equatable where Element: Equatable { }
extension Three: Sendable where Element: Sendable { }

// Board (player가 9개 가지고 있는 상태)
extension Three<Three<Player?>> {
    //Three<
    //  Three(Player?,Player?,Player?)
    //  Three(Player?,Player?,Player?)
    //  Three(Player?,Player?,Player?)
    // >
    public static let empty = Self(.init(nil, nil, nil), .init(nil, nil, nil), .init(nil, nil, nil))
    
    
    public var isFilled: Bool {
        self.allSatisfy { $0.allSatisfy { $0 != nil }}
    }
    
    public var hasWinner: Bool {
        hasWin(.o) || hasWin(.x)
    }
    
    public func hasWin(_ player: Player) -> Bool {
        
        let winConditions = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // 가로줄 3개
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // 세로줄 3개
            [0, 4, 8], [6, 4, 2] // 대각선 2개
        ]
        
        for condition in winConditions {
            
            let matches: [Player?] = condition.map {
                // 3x3의 보드에서 실제 값을 가져와서 매칭이 되는지 확인
                
                // % - 나머지계산
                // 0,1,2, 3,4,5, 6,7,8 (index)
                // 0,1,2, 0,1,2, 0,1,2 (value)
                let row = $0 % 3 // 0~2
                
                // 小数点切り捨て
                // 0,1,2, 3,4,5, 6,7,8 (index)
                // 0,0,0, 1,1,1, 2,2,2 (value)
                let column = $0 / 3 // 0~2
                
                // 1차원 인덱스를 2차원 좌표로 바꾸는 것 (0,0)
                return self[row][column]
            }
            
            let matchCount: Int = matches.filter { $0 == player }.count
            
            if matchCount == 3 {
                return true
            }
        }
        return false
    }
}


extension Three: @MainActor MutableCollection {
    
    // yield -  _read / _modify같은 빌려주는 접근자에서만 사용할 수 있는 특별한 키워드
    // yield - 이 값을 잠깐 빌려 쓸수 있게 넘긴다.
    
    // return value - 값을 복사해서 반환
    // yield value - 값(또는 참조) 을 잠깐 빌려줌
    // yield &value - inout(주소) 로 빌려줌 - 제자리 수정가능
    
    // _read / _modify - get/set과 달리 값을 복사하는 코스트가 없이/ 바로 값을 잠깐 빌려주므로
    // 값이 큰 연산을 사용할때 퍼포먼스 향상을 기대할 수 있다
    public subscript(offset: Int) -> Element {
        _read {
            switch offset {
            case 0: yield self.first
            case 1: yield self.second
            case 2: yield self.third
            default: fatalError()
            }
        }

        _modify {
            switch offset {
            case 0: yield &self.first
            case 1: yield &self.second
            case 2: yield &self.third
            default: fatalError()
            }
        }
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { 3 }
    public func index(after i: Int) -> Int { i + 1 }
}

