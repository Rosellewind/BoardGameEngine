//
//  Player.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import Foundation

enum Direction: Int {
    case top, bottom, right, left
    static let allValues = [top, bottom, right, left]
    init(loopingRawValue: Int) {
        self = Direction(rawValue: (loopingRawValue % Direction.allValues.count))!
    }
}

class Player {
    var name: String?
    let id: Int
    var forwardDirection: Direction
    var pieces: [Piece]

    init(name: String?, id: Int, forwardDirection: Direction, pieces: [Piece]) {
        self.name = name
        self.id = id
        self.forwardDirection = forwardDirection
        self.pieces = pieces
        pieces.forEach({$0.player = self})
    }
    
    deinit {
        print("deinit Player")
    }
    
    func copy() -> Player {
        return Player(name: name, id: id, forwardDirection: forwardDirection, pieces: pieces.map({$0.copy()}))
    }
}

func == (lhs: Player, rhs: Player) -> Bool {
    return lhs.id == rhs.id
}

func != (lhs: Player, rhs: Player) -> Bool {
    return lhs.id != rhs.id
}
