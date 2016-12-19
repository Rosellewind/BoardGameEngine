//
//  Chess Pieces.swift
//  Chess
//
//  Created by Roselle Milvich on 10/17/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


enum ChessPieceType: String {
    case King, Queen, Rook, Bishop, Knight, Pawn
}

class PawnPiece: Piece {
    var roundWhenPawnAdvancedTwo: Int?
}

class ChessPieceCreator: PiecesCreator {
    static let shared = ChessPieceCreator()
    func makePieces(_ variation: ChessVariation.RawValue, playerId: Int) -> [Piece] {
        let position = ChessPlayerOrientation(rawValue: playerId) ?? ChessPlayerOrientation.bottom
        var pieces = [Piece]()
        switch ChessVariation(rawValue: variation) ?? ChessVariation.standardChess {
        case .standardChess, .holeChess:
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
            
            // set starting positions
            if position == .top || position == .bottom {
                rook2.position = Position(row: 0, column: 7)
                bishop2.position = Position(row: 0, column: 5)
                knight2.position = Position(row: 0, column: 6)
                
                pawns.append(pawn)
                for i in 1..<8 {
                    let pawnI = pawn.copy() as! Piece
                    pawnI.position = Position(row: pawn.position.row, column: i)
                    pawns.append(pawnI)
                }
                
                if position == .bottom {
                    for piece in royalty {
                        piece.position = Position(row: 7, column: piece.position.column)
                    }
                    for piece in pawns {
                        piece.position = Position(row: 6, column: piece.position.column)
                    }
                }
            } else {
                
            }
            
            pieces.append(contentsOf: royalty)
            pieces.append(contentsOf: pawns)
            
        case .galaxyChess:
            let isPossibleTranslation: (Translation) -> Bool = {_ in return true}
            let isLegalMove = { (translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                return (true, nil)
            }
            let piece = Piece(name: "ship", position: Position(row: 3, column: 3), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
            pieces.append(piece)
            
        case .fourPlayer, .fourPlayerX:
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
            
            // set starting positions
            if position == .top || position == .bottom {
                king.position = Position(row: 0, column: 6)
                queen.position = Position(row: 0, column: 5)
                rook.position = Position(row: 0, column: 2)
                rook2.position = Position(row: 0, column: 9)
                bishop.position = Position(row: 0, column: 4)
                bishop2.position = Position(row: 0, column: 7)
                knight.position = Position(row: 0, column: 3)
                knight2.position = Position(row: 0, column: 8)
                
                pawn.position = Position(row: 1, column: 2)
                pawns.append(pawn)
                for i in 1..<8 {
                    let pawnI = pawn.copy() as! Piece
                    pawnI.position = Position(row: pawn.position.row, column: i + 2)
                    pawns.append(pawnI)
                }
                
                if position == .bottom {
                    for piece in royalty {
                        piece.position = Position(row: 11, column: piece.position.column)
                    }
                    for piece in pawns {
                        piece.position = Position(row: 10, column: piece.position.column)
                    }
                }
            } else {
                king.position = Position(row: 5, column: 0)
                queen.position = Position(row: 6, column: 0)
                rook.position = Position(row: 2, column: 0)
                rook2.position = Position(row: 9, column: 0)
                bishop.position = Position(row: 4, column: 0)
                bishop2.position = Position(row: 7, column: 0)
                knight.position = Position(row: 3, column: 0)
                knight2.position = Position(row: 8, column: 0)
                
                pawn.position = Position(row: 2, column: 1)
                pawns.append(pawn)
                for i in 1..<8 {
                    let pawnI = pawn.copy() as! Piece
                    pawnI.position = Position(row: i + 2, column: pawn.position.column)
                    pawns.append(pawnI)
                }
                
                if position == .right {
                    for piece in royalty {
                        piece.position = Position(row: piece.position.row, column: 11)
                    }
                    for piece in pawns {
                        piece.position = Position(row: piece.position.row, column: 10)
                    }
                }
            }
            
            pieces.append(contentsOf: royalty)
            pieces.append(contentsOf: pawns)
//        default:
//            print("implement")
        }
        
        // set the id and isFirstMove
        let offset = position.rawValue * pieces.count
        for i in 0..<pieces.count {
            pieces[i].id = i + offset
            pieces[i].isFirstMove = true
        }
        return pieces
    }
    
    func chessPiece(_ name: ChessPieceType) -> Piece {
        switch name {
        case .King:
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                if translation.row == 0 && translation.column == 0 {
                    return false
                } else {
                    return (translation.row == 0 || translation.row == -1 || translation.row == 1) && (translation.column == 0 || translation.column == -1 || translation.column == 1)
                }
            }
            
            let isLegalMove = {(translation: Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var conditions: [LegalIf]? = nil
                
                // exactly one square horizontally, vertically, or diagonally, 1 castling per game
                ////only one
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if (translation.row == 0 || translation.row == -1 || translation.row == 1) && (translation.column == 0 || translation.column == -1 || translation.column == 1){
                    isLegal = true
                    conditions = [LegalIf(condition: CantBeOccupiedBySelf.shared, translations: [translation]), LegalIf(condition: CantBeInCheck.shared, translations: [translation])]

                } else if translation.row == 0 && abs(translation.column) ==  2 {
                    // Castling:
                    // king moves 2 horizontally, rook goes where king just crossed
                    // 1. neither king nor rook has moved
                    // 2. there are no pieces between king and rook
                    // 3. "One may not castle out of, through, or into check." (rook can be under attack, just not the king)
                    
                    let signage = translation.column > 0 ? 1 : -1
                    isLegal = true
                    // rookCanCastleCondition: rook hasn't moved yet, no pieces from next to landing to rook
                    
                    let kingFirstMoveCondition = LegalIf(condition: IsInitialMove.shared, translations: nil)
                    let rookCanCastleCondition = LegalIf(condition: RookCanCastle.shared, translations: [translation])
                    let mustBeVacantCellsFromKingToKingLandingCondition = LegalIf(condition: MustBeVacantCell.shared, translations: [translation, Translation(row: translation.row, column: (abs(translation.column) - 1) * signage)])
                    let cantBeInCheckDuringCondition = LegalIf(condition: CantBeInCheck.shared, translations: [Translation(row: 0, column: 0), Translation(row:0, column: (abs(translation.column) - 1) * signage), translation])
                    conditions = [kingFirstMoveCondition, rookCanCastleCondition, mustBeVacantCellsFromKingToKingLandingCondition, cantBeInCheckDuringCondition]
                }
                return (isLegal, conditions)
            }
            return Piece(name: name.rawValue, position: Position(row: 0, column: 4), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
        case .Queen:
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                if translation.row == 0 && translation.column == 0 {
                    return false
                } else {
                    let horizontal = translation.row == 0
                    let vertical = translation.column == 0
                    let diagonal = abs(translation.row) == abs(translation.column)
                    return horizontal || vertical || diagonal
                }
            }
            
            let isLegalMove = { (translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var mustBeVacantCell = [Position]()
                var conditions = [LegalIf(condition: CantBeOccupiedBySelf.shared, translations: [translation])]
                
                // any number of vacant squares in a horizontal, vertical, or diagonal direction.
                let horizontal = translation.row == 0
                let vertical = translation.column == 0
                let diagonal = abs(translation.row) == abs(translation.column)
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if horizontal {  // horizontal
                    let signage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.column) {
                        mustBeVacantCell.append(Position(row: 0, column: i * signage))
                    }
                    isLegal = true
                } else if vertical { // vertical
                    let signage = translation.row > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        mustBeVacantCell.append(Position(row: i * signage, column: 0))
                    }
                    isLegal = true
                } else if diagonal {    // diagonal
                    let rowSignage = translation.row > 0 ? 1 : -1
                    let columnSignage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        mustBeVacantCell.append(Position(row: i * rowSignage, column: i * columnSignage))
                    }
                    isLegal = true
                }
                if mustBeVacantCell.count > 0 {
                    conditions.append(LegalIf(condition: MustBeVacantCell.shared, translations: mustBeVacantCell))
                }
                conditions.append(LegalIf(condition: CantBeInCheck.shared, translations: [translation]))
                return (isLegal, conditions)
            }
            return Piece(name: name.rawValue, position: Position(row: 0, column:  3), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
        case .Rook:
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                if translation.row == 0 && translation.column == 0 {
                    return false
                } else {
                    let horizontal = translation.row == 0
                    let vertical = translation.column == 0
                    return horizontal || vertical
                }
            }
            
            let isLegalMove = {(translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var mustBeVacantCell = [Position]()
                var conditions = [LegalIf(condition: CantBeOccupiedBySelf.shared, translations: [translation])]
                
                // any number of vacant squares in a horizontal or vertical direction, also moved in castling
                let horizontal = translation.row == 0
                let vertical = translation.column == 0
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if horizontal {  // horizontal
                    let signage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.column) {
                        mustBeVacantCell.append(Position(row: 0, column: i * signage))
                    }
                    isLegal = true
                } else if vertical { // vertical
                    let signage = translation.row > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        mustBeVacantCell.append(Position(row: i * signage, column: 0))
                    }
                    isLegal = true
                }
                if mustBeVacantCell.count > 0 {
                    conditions.append(LegalIf(condition: MustBeVacantCell.shared, translations: mustBeVacantCell))
                }
                conditions.append(LegalIf(condition: CantBeInCheck.shared, translations: [translation]))
                return (isLegal, conditions)
            }
            return Piece(name: name.rawValue, position: Position(row: 0, column: 0), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
        case .Bishop:
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                if translation.row == 0 && translation.column == 0 {
                    return false
                } else {
                    let diagonal = abs(translation.row) == abs(translation.column)
                    return diagonal
                }
                
            }
            
            let isLegalMove = { (translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var mustBeVacantCell = [Position]()
                
                // can't land on self or leave self in check
                var conditions = [LegalIf(condition: CantBeOccupiedBySelf.shared, translations: [translation])]
                
                // any number of vacant squares in any diagonal direction
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == abs(translation.column) {    // diagonal
                    let rowSignage = translation.row > 0 ? 1 : -1
                    let columnSignage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        mustBeVacantCell.append(Position(row: i * rowSignage, column: i * columnSignage))
                    }
                    isLegal = true
                }
                if mustBeVacantCell.count > 0 {
                    conditions.append(LegalIf(condition: MustBeVacantCell.shared, translations: mustBeVacantCell))
                }
                conditions.append(LegalIf(condition: CantBeInCheck.shared, translations: [translation]))
                return (isLegal, conditions)
            }
            return Piece(name: name.rawValue, position: Position(row: 0, column: 2), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
        case .Knight:
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                return abs(translation.row) == 2 && abs(translation.column) == 1 || abs(translation.row) == 1 && abs(translation.column) == 2
            }
            
            let isLegalMove = { (translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var conditions: [LegalIf]?
                
                // the nearest square not on the same rank, file, or diagonal, L, 2 steps/1 step
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == 2 && abs(translation.column) == 1 || abs(translation.row) == 1 && abs(translation.column) == 2 {
                    isLegal = true
                    conditions = [LegalIf(condition: CantBeOccupiedBySelf.shared, translations: [translation]), LegalIf(condition: CantBeInCheck.shared, translations: [translation])]
                }
                return (isLegal, conditions)
            }
            return Piece(name: name.rawValue, position: Position(row: 0, column: 1), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
        case .Pawn:
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                let forwardTwo = translation.row == 2 && translation.column == 0
                let forwardOne = translation.row == 1 && translation.column == 0
                let diagonalOne = translation.row == 1 && abs(translation.column) == 1
                return forwardTwo || forwardOne || diagonalOne
            }
            
            let isLegalMove = { (translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var conditions = [LegalIf(condition: CheckForPromotion.shared, translations: nil)]

                
                
                let forwardTwo = translation.row == 2 && translation.column == 0
                let forwardOne = translation.row == 1 && translation.column == 0
                let diagonalOne = translation.row == 1 && abs(translation.column) == 1
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if forwardTwo {  // initial move, forward two
                    isLegal = true
                    conditions.append(LegalIf(condition: IsInitialMove.shared, translations: nil))
                    conditions.append(LegalIf(condition: MustBeVacantCell.shared, translations: [Position(row: 1, column: 0), Position(row: 2, column: 0)]))
                    conditions.append(LegalIf(condition: MarkAdvancedTwo.shared, translations: nil))
                } else if forwardOne {     // move forward one on vacant
                    isLegal = true
                    conditions.append(LegalIf(condition: MustBeVacantCell.shared, translations: [translation]))
                } else if diagonalOne {    // move diagonal one on occupied
                    isLegal = true
                    conditions.append(LegalIf(condition: MustBeOccupiedByOpponentOrEnPassant.shared, translations: [translation, Translation(row: 0, column:translation.column)]))
                }
                conditions.append(LegalIf(condition: CantBeInCheck.shared, translations: [translation]))
                return (isLegal, conditions)
            }
            
            let piece = PawnPiece(name: name.rawValue, position: Position(row: 1, column: 0), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove)
            return piece
        }}
}
