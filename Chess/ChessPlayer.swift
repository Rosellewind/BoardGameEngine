//
//  ChessPlayer.swift
//  Chess
//
//  Created by Roselle Milvich on 10/17/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

enum ChessPlayerOrientation: Int {
    case bottom, top, left, right
    func color() -> String {
        switch self {
        case .bottom:
            return "White"
        case .top:
            return "Black"
        case .left:
            return "Red"
        case .right:
            return "Blue"
        }
    }
    func defaultColor() -> String {
        return "White"
    }
}

class ChessPlayer: Player {
    var orientation: ChessPlayerOrientation {
        return ChessPlayerOrientation(rawValue: self.id) ?? ChessPlayerOrientation.bottom
    }
    init(index: Int, variation: Int, board: Board) {
        let pieces = ChessPieceCreator.shared.makePieces(variation: variation, playerId: index, board: board)
        super.init(name: nil, id: index, forwardDirection: nil, pieces: pieces)
        self.name = self.orientation.color()
    }
}
