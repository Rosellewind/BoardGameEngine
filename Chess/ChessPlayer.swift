//
//  ChessPlayer.swift
//  Chess
//
//  Created by Roselle Milvich on 10/17/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


class ChessPlayer: Player {
    init(index: Int, variation: ChessVariation, board: Board) {
        let pieces = ChessPieceCreator.shared.makePieces(variation: variation, playerId: index, board: board)
        super.init(name: nil, id: index, forwardDirection: Direction(rawValue: index) ?? Direction.top, pieces: pieces)
        self.name = color(direction: self.forwardDirection)
    }
    
    func color(direction: Direction) -> String {
        switch direction {
        case .bottom:
            return "Black"
        case .top:
            return "White"
        case .left:
            return "Blue"
        case .right:
            return "Red"
        }
    }
}
