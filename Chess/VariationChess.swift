//
//  VariationChess.swift
//  Chess
//
//  Created by Roselle Milvich on 6/13/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

enum ChessVariation {
    case StandardChess, Galaxy
}

enum TurnCondition {
    case CantExposeKing
}

enum ChessPlayer: Int {
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

enum ChessPiece: String {
    case King, Queen, Rook, Bishop, Knight, Pawn
}


class ChessGamez {
    func makeChessGame(board: &Board, boardView: BoardView, players: [Player], pieceViews = [PieceView], turnConditions: [TurnCondition]?) {
        board
    }
    
    
    static func standardPieces(variation: ChessVariation, chessPlayer: ChessPlayer) -> [Piece]{
        var pieces = [Piece]()
        switch variation {
        case .StandardChess:
            let king = self.chessPiece(.King)
            let queen = self.chessPiece(.Queen)
            let rook = self.chessPiece(.Rook)
            let bishop = self.chessPiece(.Bishop)
            let knight = self.chessPiece(.Knight)
            let pawn = self.chessPiece(.Pawn)
            let rook2 = rook.copy() as! Piece
            let bishop2 = bishop.copy() as! Piece
            let knight2 = knight.copy() as! Piece
            let royalty: [Piece] = [king, queen, rook, bishop, knight, rook2, bishop2, knight2]
            var pawns = [Piece]()
            
            
            if chessPlayer == .top || chessPlayer == .bottom {
                rook2.position = Position(row: 0, column: 7)
                bishop2.position = Position(row: 0, column: 5)
                knight2.position = Position(row: 0, column: 6)
                
                pawns.append(pawn)
                for i in 1..<8 {
                    let pawnI = pawn.copy() as! Piece
                    pawnI.position = Position(row: pawn.position.row, column: i)
                    pawns.append(pawnI)
                }
                
                if chessPlayer == .bottom {
                    for piece in royalty {
                        piece.position = Position(row: 7, column: piece.position.column)
                    }
                    for piece in pawns {
                        piece.position = Position(row: 6, column: piece.position.column)
                    }
                }
            } else {
                
            }
            
            pieces.appendContentsOf(royalty)
            pieces.appendContentsOf(pawns)
            
        case .Galaxy:
            let piece = Piece(name: "ship", position: Position(row: 3, column: 3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                return (true, nil)
            })
            pieces.append(piece)
        }
        
        // set the tag
        let offset = chessPlayer.rawValue * pieces.count
        for i in 0..<pieces.count {
            pieces[i].tag = i + offset
        }
        return pieces
    }

    
    static func chessPiece(name: ChessPiece) -> Piece {
        switch name {
        case .King:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 4), isLegalMove: {(translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: LegalIfCondition, positions: [Position]?)]?
                
                // exactly one square horizontally, vertically, or diagonally, 1 castling per game
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if (translation.row == 0 || translation.row == -1 || translation.row == 1) && (translation.column == 0 || translation.column == -1 || translation.column == 1){
                    isLegal = true
                    conditions = [(.CantBeOccupiedBySelf, [translation])]
                } else if translation.row == 0 && abs(translation.column) ==  2 {
                    // Castling:
                    // 1. neither king nor rook has moved
                    // 2. there are no pieces between king and rook
                    // 3. "One may not castle out of, through, or into check."
                    // into check is already being checked///////////every piece have can't go into check? do I need turn conditions?
                    let signage = translation.column > 0 ? 1 : -1
                    isLegal = true
                    conditions = [(.IsInitialMove, nil), (.RookCanCastle, [translation]), (.CantBeOccupied,[translation, Position(row: translation.row, column: (abs(translation.column) - 1) * signage)]), (.CantBeInCheckDuring, [Position(row: 0, column: 0), Position(row:0, column: (abs(translation.column) - 1) * signage), translation])]
                }
                return (isLegal, conditions)
            })
        case .Queen:
            return Piece(name: name.rawValue, position: Position(row: 0, column:  3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: LegalIfCondition, positions: [Position]?)] = [(condition: .CantBeOccupiedBySelf, positions: [translation])]
                
                // any number of vacant squares in a horizontal, vertical, or diagonal direction.
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 0 {  // horizontal
                    let signage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.column) {
                        cantBeOccupied.append(Position(row: 0, column: i * signage))
                    }
                    isLegal = true
                } else if translation.column == 0 { // vertical
                    let signage = translation.row > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        cantBeOccupied.append(Position(row: i * signage, column: 0))
                    }
                    isLegal = true
                } else if abs(translation.row) == abs(translation.column) {    // diagonal
                    let rowSignage = translation.row > 0 ? 1 : -1
                    let columnSignage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        cantBeOccupied.append(Position(row: i * rowSignage, column: i * columnSignage))
                    }
                    isLegal = true
                }
                if cantBeOccupied.count > 0 {
                    conditions.append((.CantBeOccupied, cantBeOccupied))
                }
                return (isLegal, conditions)
            })
        case .Rook:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: LegalIfCondition, positions: [Position]?)] = [(condition: .CantBeOccupiedBySelf, positions: [translation])]
                
                // any number of vacant squares in a horizontal or vertical direction, also moved in castling
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 0 {  // horizontal
                    let signage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.column) {
                        cantBeOccupied.append(Position(row: 0, column: i * signage))
                    }
                    isLegal = true
                } else if translation.column == 0 { // vertical
                    let signage = translation.row > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        cantBeOccupied.append(Position(row: i * signage, column: 0))
                    }
                    isLegal = true
                }
                if cantBeOccupied.count > 0 {
                    conditions.append((.CantBeOccupied, cantBeOccupied))
                }
                return (isLegal, conditions)
            })
        case .Bishop:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 2), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                
                // can't land on self
                var conditions: [(condition: LegalIfCondition, positions: [Position]?)] = [(condition: .CantBeOccupiedBySelf, positions: [translation])]
                
                // any number of vacant squares in any diagonal direction
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == abs(translation.column) {    // diagonal
                    let rowSignage = translation.row > 0 ? 1 : -1
                    let columnSignage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        cantBeOccupied.append(Position(row: i * rowSignage, column: i * columnSignage))
                    }
                    isLegal = true
                }
                if cantBeOccupied.count > 0 {
                    conditions.append((.CantBeOccupied, cantBeOccupied))
                }
                return (isLegal, conditions)
            })
        case .Knight:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 1), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: LegalIfCondition, positions: [Position]?)]?
                
                // the nearest square not on the same rank, file, or diagonal, L, 2 steps/1 step
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == 2 && abs(translation.column) == 1 || abs(translation.row) == 1 && abs(translation.column) == 2{
                    isLegal = true
                    conditions = [(.CantBeOccupiedBySelf, [translation])]
                }
                return (isLegal, conditions)
            })
            
        case .Pawn:
            let piece = Piece(name: name.rawValue, position: Position(row: 1, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: LegalIfCondition, positions: [Position]?)]?
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 2 && translation.column == 0 {  // initial move, forward two
                    isLegal = true
                    conditions = [(.CantBeOccupied, [Position(row: 1, column: 0), Position(row: 2, column: 0)]), (.IsInitialMove, nil)]
                    return (isLegal, conditions)
                } else if translation.row == 1 && translation.column == 0 {     // move forward one on vacant
                    isLegal = true
                    conditions = [(.CantBeOccupied, [translation])]
                } else if translation.row == 1 && abs(translation.column) == 1 {    // move diagonal one on occupied
                    isLegal = true
                    conditions = [(.MustBeOccupiedByOpponent, [translation])]
                }
                return (isLegal, conditions)
            })
            return piece
        }
    }
}

