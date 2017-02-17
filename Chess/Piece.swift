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

class Piece: NSObject, NSCopying {
    var name: String
    var id = 0
    dynamic var position: Position  
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
    dynamic var selected = false
    weak var player: Player?
    
    init(name: String, position: Position, isPossibleTranslation: @escaping (_ : Translation) -> Bool, isLegalMove: @escaping IsLegalMove) {
        self.name = name
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
    
    func copy(with zone: NSZone?) -> Any {
        return type(of: self).init(toCopy: self)
    }   
}

class PieceCreator: PiecesCreator {
    static let shared = PieceCreator()
    
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
        
        // set the id and isFirstMove
        let offset = playerId * pieces.count
        for i in 0..<pieces.count {
            pieces[i].id = i + offset
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
        
        // set the id and isFirstMove
        let offset = playerId * pieces.count
        for i in 0..<pieces.count {
            pieces[i].id = i + offset
            pieces[i].isFirstMove = true
        }
        return pieces
    }
}


private var myContext = 0
protocol PieceViewProtocol: class {
    func animateMove(_ pieceView: PieceView, position: Position, duration: TimeInterval)
}

class PieceView: UIImageView {
    var positionConstraints = [NSLayoutConstraint]()
    weak var delegate: PieceViewProtocol?
    var observing: [(objectToObserve: NSObject, keyPath: String)]? {
        willSet {
            for observe in observing ?? [] {
                observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
            }
        }
        didSet {
            for observe in observing ?? [] {
                observe.objectToObserve.addObserver(self, forKeyPath: observe.keyPath, options: [.new, .old], context: &myContext)
            }
        }
    }

    init(image: UIImage, pieceTag: Int) {
        super.init(image:image)
        self.tag = pieceTag
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if keyPath == "selected" {
                if let new = change?[NSKeyValueChangeKey.newKey] as? Bool {
                    if new == true {
                        self.alpha = 0.4
                    } else {
                        self.alpha = 1.0
                    }
                }
            } else if keyPath == "position" {
                if let new = change?[NSKeyValueChangeKey.newKey] as? Position {
                    delegate?.animateMove(self, position: new, duration: 0.5)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        print("deinit PieceView")
        for observe in observing ?? [] {
            observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
        }
        observing = nil
    }
    
    func constrainToCell(_ cell: UIView) {
        print(self.constraints)
        print(".....")
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: cell, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: cell, attribute: .height, multiplier: 1, constant: 0)
        let positionX = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: cell, attribute: .centerX, multiplier: 1, constant: 0)
        let positionY = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0)
        positionConstraints = [positionX, positionY]
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, positionX, positionY])
    }
}
