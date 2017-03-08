//
//  Piece.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//


import UIKit


protocol PiecesCreator {
    func makePieces(variation: GameVariation, playerId: Int, board: Board) -> [Piece]
}




struct LegalIf {
    let condition: Condition
    let translations: [Translation]?
}

typealias IsLegalMove = (_ : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?)

class Piece: Equatable {
    var name: String
    var id: Int
    var position: Position
        {
        didSet {
            self.isFirstMove = false
        }
    }
    var startingPosition: Position
    var isPossibleTranslation: (_ : Translation) -> Bool
    var isLegalMove: IsLegalMove
    var removePieceOccupyingNewPosition = true
    var isFirstMove: Bool
    var selected = false {
        didSet {
            if self.pieceView != nil {
                self.pieceView!.alpha = selected ? 0.4: 1.0
            }
        }
    }
    weak var player: Player?
    weak var pieceView: PieceView?
    
    class func nextID() -> Int {
        struct Holder {
            static var count = 0
        }
        Holder.count += 1
        return Holder.count
    }
    
    init(name: String, position: Position, isPossibleTranslation: @escaping (_ : Translation) -> Bool, isLegalMove: @escaping IsLegalMove) {
        self.name = name
        self.id = Piece.nextID()
        self.position = position
        self.startingPosition = position
        self.isPossibleTranslation = isPossibleTranslation
        self.isLegalMove = isLegalMove
        self.isFirstMove = true
    }
    
    required init(toCopy: Piece) {
        self.name = toCopy.name
        self.id = toCopy.id
        self.position = toCopy.position
        self.startingPosition = toCopy.position
        self.isPossibleTranslation = toCopy.isPossibleTranslation
        self.isLegalMove = toCopy.isLegalMove
        self.isFirstMove = toCopy.isFirstMove
        self.selected = toCopy.selected
        self.player = toCopy.player
    }
    
    
    deinit {
        print("deinit Piece")
    }
    
    func copy() -> Piece {
        return Piece(toCopy: self)
    }
    
    func copyWithNewID() -> Piece {
        let copy = self.copy()
        copy.id = Piece.nextID()
        return copy
    }
    
    static func == (lhs: Piece, rhs: Piece) -> Bool {
        return lhs.id == rhs.id
    }
}

class PieceCreator: PiecesCreator {
    static let shared: PieceCreator = PieceCreator()
    
    func basicSquareAndCirclePieces(playerId: Int, board: Board, deleteEdgeCells: Bool) -> [Piece] {
        var pieces = [Piece]()

        // make square pieces
        var column = playerId == 0 ? 0 : board.numColumns - 1
        for row in 0..<board.numRows {
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                if translation.row == 0 && translation.column == 0 {
                    return false
                } else {    // move or jump one vertically or horizontally
                    return (translation.row == 0 && (abs(translation.column) == 1 || abs(translation.column) == 2)) || (translation.column == 0 && (abs(translation.row) == 1 || abs(translation.row) == 2))
                }
            }
            
            let isLegalMove = {(translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var conditions: [LegalIf]? = nil
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if (translation.row == 0 && abs(translation.column) == 1) || (translation.column == 0 && abs(translation.row) == 1) {    // move one vertically or horizontally if vacant
                    isLegal = true
                    conditions = [LegalIf(condition: MustBeVacantCell(), translations: [translation])]
                } else if (translation.row == 0 && abs(translation.column) == 2) || (translation.column == 0 && abs(translation.row) == 2) {
                    isLegal = true
                    var jumpedRow = translation.row
                    jumpedRow.stepTowardsZero()
                    var jumpedColumn = translation.column
                    jumpedColumn.stepTowardsZero()
                    let jumpedTranslation = Translation(row: jumpedRow, column: jumpedColumn)
                    conditions = [LegalIf(condition: MustBeVacantCell(), translations: [translation]), LegalIf(condition: MustBeOccupiedByOpponent(), translations: [jumpedTranslation]), LegalIf(condition: RemoveOpponent(), translations: [jumpedTranslation])]
                }
                
                if conditions != nil && deleteEdgeCells == true {
                    let condition: LegalIf = LegalIf(condition: DeleteEdgeCellsTouchingAllEmpty(), translations: [translation])
                    conditions!.append(condition)
                }
                
                return (isLegal, conditions)
            }
            
            pieces.append(Piece(name: "Square", position: Position(row: row, column: column), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove))
            
        }
        
        // make round pieces
        column = playerId == 0 ? 1 : board.numColumns - 2
        for row in 0..<board.numRows {
            let isPossibleTranslation = {(translation: Translation) -> Bool in
                if translation.row == 0 && translation.column == 0 {
                    return false
                } else {                        // move or jump one diagonally
                    return (abs(translation.row) == 1 && abs(translation.column) == 1) || (abs(translation.row) == 2 && abs(translation.column) == 2)
                }
            }
            
            let isLegalMove = {(translation : Translation) -> (isLegal: Bool, legalIf: [LegalIf]?) in
                var isLegal = false
                var conditions: [LegalIf]? = nil
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == 1 && abs(translation.column) == 1 {    // move one diagonally if vacant
                    isLegal = true
                    conditions = [LegalIf(condition: MustBeVacantCell(), translations: [translation])]
                } else if abs(translation.row) == 2 && abs(translation.column) == 2 {
                    isLegal = true
                    var jumpedRow = translation.row
                    jumpedRow.stepTowardsZero()
                    var jumpedColumn = translation.column
                    jumpedColumn.stepTowardsZero()
                    let jumpedTranslation = Translation(row: jumpedRow, column: jumpedColumn)
                    conditions = [LegalIf(condition: MustBeVacantCell(), translations: [translation]), LegalIf(condition: MustBeOccupiedByOpponent(), translations: [jumpedTranslation]), LegalIf(condition: RemoveOpponent(), translations: [jumpedTranslation])]
                }
                
                if conditions != nil && deleteEdgeCells == true {
                    let condition: LegalIf = LegalIf(condition: DeleteEdgeCellsTouchingAllEmpty(), translations: [translation])
                    conditions!.append(condition)
                }
                
                return (isLegal, conditions)
            }
            
            pieces.append(Piece(name: "Circle", position: Position(row: row, column: column), isPossibleTranslation: isPossibleTranslation, isLegalMove: isLegalMove))
        }
        
        // set isFirstMove
        for i in 0..<pieces.count {
            pieces[i].isFirstMove = true
        }
        
        return pieces
    }
    
    func makePieces(variation: GameVariation, playerId: Int, board: Board) -> [Piece] {
        guard let variation = variation as? UniqueVariation else {
            return []
        }
        var pieces: [Piece]
        switch variation {
        case .galaxy:
            pieces = basicSquareAndCirclePieces(playerId: playerId, board: board, deleteEdgeCells: false)
            
        case .blackHole:
            pieces = basicSquareAndCirclePieces(playerId: playerId, board: board, deleteEdgeCells: true)
        }
        
        // set  isFirstMove
        pieces.forEach({$0.isFirstMove = true})

        return pieces
    }
}


