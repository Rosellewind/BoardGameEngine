//
//  Player.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import Foundation

enum PlayerOrientation: Int {
    case bottom, top, left, right
    func colorString() -> String {
        switch self {
        case bottom:
            return "White"
        case top:
            return "Black"
        case left:
            return "Red"
        case right:
            return "Blue"
        }
    }
}


class Player {
    let orientation: PlayerOrientation
    var pieces: [Piece]
    
    init(orientation: PlayerOrientation, pieces: [Piece]) {
        self.orientation = orientation
        self.pieces = pieces
    }
    
    init(variation: ChessVariation, orientation: PlayerOrientation) {
        self.orientation = orientation
        self.pieces = Piece.standardPieces(variation, playerOrientation: orientation)
    }
}