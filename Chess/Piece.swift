//
//  Piece.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

struct Move {
    // up and down, side to side, diagonal right, diagonal left
}

struct Piece {
    let name: String
    let position: Position
    let startingPosition: Position
    let isLegalMove: ((Int) -> Bool)
    
    init(name: String, position: Position, isLegalMove: ((Int) -> Bool)) {
        self.name = name
        self.position = position
        self.startingPosition = position
        self.isLegalMove = isLegalMove
    }
    
    static func standardPieces(variation: ChessVariation, playerOrientation: PlayerOrientation) -> [Piece]{
        let pieces = [Piece]()
//        switch variation {
//        case .StandardChess:
//            let x = 0
////            let king = Piece(name: "King", moves: <#T##[Position]#>, position: <#T##Position#>)
////            let rook = Piece(name: "Rook", moves: , position: )
//        }
////        let move = {}
        return pieces
    }
}

class PieceView: UIView {
    
}
