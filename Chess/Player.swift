//
//  Player.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import Foundation


enum Direction: Int {
    case top, bottom, left, right
    static let allValues = [top, bottom, left, right]
    init(loopingRawValue: Int) {
        self = Direction(rawValue: (loopingRawValue % Direction.allValues.count))!
    }
}

class Player {
    var name: String?
    let index: Int  //// id?
    var forwardDirection: Direction
    var pieces: [Piece]

    init(name: String?, index: Int, forwardDirection: Direction?, pieces: [Piece]) {
        self.name = name
        self.index = index
        self.forwardDirection = forwardDirection ?? Direction(loopingRawValue: index)
        self.pieces = pieces
    }
}