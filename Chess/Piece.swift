//
//  Piece.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//


import UIKit

enum ChessPiece: String {
    case King, Queen, Rook, Bishop, Knight, Pawn
}

enum LegalIfCondition {
    case MustBeOccupied, CantBeOccupied, MustBeOccupiedByOpponent, CantBeOccupiedBySelf, IsInitialMove, RookIsInitialMove, RookIsAlsoLegalMove, CantBeInCheckDuring//rename IsInitialMove
}

class Piece: NSObject, NSCopying {
    var name: String
    var position: Position
    let startingPosition: Position
    var isLegalMove: (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?)
    dynamic var selected = false
    var tag = 0
    var isFirstMove = true
    
    init(name: String, position: Position, isLegalMove: (Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?)) {
        self.name = name
        self.position = position
        self.startingPosition = position
        self.isLegalMove = isLegalMove
    }
    
    required init(toCopy: Piece) {
        self.name = toCopy.name
        self.tag = toCopy.tag
        self.position = toCopy.position
        self.startingPosition = toCopy.position
        self.isLegalMove = toCopy.isLegalMove
        self.isFirstMove = toCopy.isFirstMove
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.init(toCopy: self)
    }
    
    static func standardPieces(variation: ChessVariation, playerOrientation: PlayerOrientation) -> [Piece]{
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
            

            if playerOrientation == .top || playerOrientation == .bottom {
                rook2.position = Position(row: 0, column: 7)
                bishop2.position = Position(row: 0, column: 5)
                knight2.position = Position(row: 0, column: 6)
                
                pawns.append(pawn)
                for i in 1..<8 {
                    let pawnI = pawn.copy() as! Piece
                    pawnI.position = Position(row: pawn.position.row, column: i)
                    pawns.append(pawnI)
                }
                
                if playerOrientation == .bottom {
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
            let piece = Piece(name: "ship", position: Position(row: 3, column: 3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                return (true, nil)
            })
            pieces.append(piece)
        }
        
        // set the tag
        let offset = playerOrientation.rawValue * pieces.count
        for i in 0..<pieces.count {
            pieces[i].tag = i + offset
        }
        return pieces
    }
    
    static func chessPiece(name: ChessPiece) -> Piece {
        switch name {
        case .King:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 4), isLegalMove: {(translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                var isLegal = false
                var conditions: [(condition: LegalIfCondition, positions: [Position])]?

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
                    conditions = [(.IsInitialMove, [Position]()), (.RookIsInitialMove, [Position]()), (.RookIsAlsoLegalMove, [Position]()), (.CantBeOccupied,[translation, Position(row: translation.row, column: (abs(translation.column) - 1) * signage)]), (.CantBeInCheckDuring, [Position(row: 0, column: 0), Position(row:0, column: (abs(translation.column) - 1) * signage), translation])]    
                }
                return (isLegal, conditions)
            })
        case .Queen:
            return Piece(name: name.rawValue, position: Position(row: 0, column:  3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: LegalIfCondition, positions: [Position])] = [(condition: .CantBeOccupiedBySelf, positions: [translation])]
                
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
            return Piece(name: name.rawValue, position: Position(row: 0, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: LegalIfCondition, positions: [Position])] = [(condition: .CantBeOccupiedBySelf, positions: [translation])]

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
            return Piece(name: name.rawValue, position: Position(row: 0, column: 2), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                
                // can't land on self
                var conditions: [(condition: LegalIfCondition, positions: [Position])] = [(condition: .CantBeOccupiedBySelf, positions: [translation])]
                
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
            return Piece(name: name.rawValue, position: Position(row: 0, column: 1), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                var isLegal = false
                var conditions: [(condition: LegalIfCondition, positions: [Position])]?

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
            let piece = Piece(name: name.rawValue, position: Position(row: 1, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position])]?) in
                var isLegal = false
                var conditions: [(condition: LegalIfCondition, positions: [Position])]?
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 2 && translation.column == 0 {  // initial move, forward two
                    isLegal = true
                    conditions = [(.CantBeOccupied, [Position(row: 1, column: 0), Position(row: 2, column: 0)]), (.IsInitialMove, [Position]())]
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


private var myContext = 0

class PieceView: UIView {
    var image: UIImage
    var positionConstraints = [NSLayoutConstraint]()
    
    var observing: [(objectToObserve: NSObject, keyPath: String)]? {
        willSet {
            for observe in observing ?? [] {
                observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
            }
        }
        didSet {
            for observe in observing ?? [] {
                observe.objectToObserve.addObserver(self, forKeyPath: observe.keyPath, options: .New, context: &myContext)
            }
        }
    }

    init(image: UIImage) {
        self.image = image
        super.init(frame: CGRectZero)
        self.userInteractionEnabled = false
        
        let imageView = UIImageView(image:image)
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(imageView))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if keyPath == "selected" {
                if let piece = object as? Piece {
                    if piece.selected == true {
                        self.alpha = 0.4
                    } else {
                        self.alpha = 1.0
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        observing = nil
    }
}
