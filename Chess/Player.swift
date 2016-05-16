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
}


class Player {
    var pieces: [Piece]
    let orientation: PlayerOrientation
    
    init(orientation: PlayerOrientation, pieces: [Piece]) {
        self.orientation = orientation
        self.pieces = pieces
    }
    
    static func chessPieces(board: Board, orientation: PlayerOrientation) -> [Piece] {
        let pieces = [Piece]()
        
        let is8WidthBoard = board.numRows == 8 && board.numColumns == 8
        if is8WidthBoard {
            
        }
        return pieces
    }
}