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

enum Condition {
    case MustBeOccupied, CantBeOccupied
}

class Piece {
    var name: String
    var position: Position
    let startingPosition: Position
    var isLegalMove: (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?)
    var selected = false
    
    init(name: String, position: Position, isLegalMove: (Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?)) {
        self.name = name
        self.position = position
        self.startingPosition = position
        self.isLegalMove = isLegalMove
    }
    
    init(toCopy: Piece) {
        self.name = toCopy.name
        self.position = toCopy.position
        self.startingPosition = toCopy.position
        self.isLegalMove = toCopy.isLegalMove
    }
    
    func copy() -> Piece{
        return Piece(toCopy: self)
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
            let rook2 = rook.copy()
            let bishop2 = bishop.copy()
            let knight2 = knight.copy()
            let royalty: [Piece] = [king, queen, rook, bishop, knight, rook2, bishop2, knight2]
            var pawns = [Piece]()
            

            if playerOrientation == .top || playerOrientation == .bottom {
                rook2.position = Position(row: 0, column: 7)
                bishop2.position = Position(row: 0, column: 5)
                knight2.position = Position(row: 0, column: 6)
                
                pawns.append(pawn)
                for i in 1..<8 {
                    let pawnI = pawn.copy()
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
            let piece = Piece(name: "ship", position: Position(row: 3, column: 3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                return (true, nil)
            })
            pieces.append(piece)
        }
        return pieces
    }
    
    static func chessPiece(name: ChessPiece) -> Piece {
        switch name {
        case .King:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 4), isLegalMove: {(translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                var isLegal = false

                // exactly one square horizontally, vertically, or diagonally, 1 castling per game
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if (translation.row == 0 || translation.row == -1 || translation.row == 1) && (translation.column == 0 || translation.column == -1 || translation.column == 1){
                    isLegal = true
                }
                return (isLegal, nil)
            })
        case .Queen:
            return Piece(name: name.rawValue, position: Position(row: 0, column:  3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Condition, positions: [Position])]?
                
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
                } else if abs(translation.row) == abs(translation.row) {    // diagonal
                    let rowSignage = translation.row > 0 ? 1 : -1
                    let columnSignage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        cantBeOccupied.append(Position(row: i * rowSignage, column: i * columnSignage))
                    }
                    isLegal = true
                }
                if cantBeOccupied.count > 1 {
                    conditions = [(.CantBeOccupied, cantBeOccupied)]
                }
                return (isLegal, conditions)
            })
        case .Rook:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Condition, positions: [Position])]?

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
                if cantBeOccupied.count > 1 {
                    conditions = [(.CantBeOccupied, cantBeOccupied)]
                }
                return (isLegal, conditions)
            })
        case .Bishop:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 2), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Condition, positions: [Position])]?
                
                // any number of vacant squares in any diagonal direction
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == abs(translation.row) {    // diagonal
                    let rowSignage = translation.row > 0 ? 1 : -1
                    let columnSignage = translation.column > 0 ? 1 : -1
                    for i in 1..<abs(translation.row) {
                        cantBeOccupied.append(Position(row: i * rowSignage, column: i * columnSignage))
                    }
                    isLegal = true
                }
                if cantBeOccupied.count > 1 {
                    conditions = [(.CantBeOccupied, cantBeOccupied)]
                }
                return (isLegal, conditions)
            })
        case .Knight:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 1), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                var isLegal = false
                
                // the nearest square not on the same rank, file, or diagonal, L, 2 steps/1 step
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == 2 && abs(translation.column) == 1 || abs(translation.row) == 1 && abs(translation.column) == 2{
                    isLegal = true
                }
                return (isLegal, nil)
            })
            
        case .Pawn:
            return Piece(name: name.rawValue, position: Position(row: 1, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Condition, positions: [Position])]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var mustBeOccupied = [Position]()
                var conditions: [(condition: Condition, positions: [Position])]?

                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 1 && translation.column == 0 {     // move forward one on vacant
                    cantBeOccupied = [translation]
                    isLegal = true
                } else if translation.row == 1 && abs(translation.column) == 1 {    // move diagonal one on occupied
                    mustBeOccupied = [translation]
                    isLegal = true
                }
                
                // conditions
                if cantBeOccupied.count > 1 {
                    conditions = [(.CantBeOccupied, cantBeOccupied)]
                }
                if mustBeOccupied.count > 1 {
                    if conditions == nil {
                        conditions = [(.MustBeOccupied, mustBeOccupied)]
                    } else {
                        conditions!.append((.MustBeOccupied, mustBeOccupied))
                    }
                }
                return (isLegal, conditions)
            })
            
        }
    }
}

class PieceView: UIView {
    var image: UIImage
    var startingPoint: CGPoint?///////////change to starting position
    init(image: UIImage, startingPoint: CGPoint) {
        self.image = image
        self.startingPoint = startingPoint
        super.init(frame: CGRectZero)
        
        self.center = startingPoint
        let imageView = UIImageView(image:image)
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(imageView))

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
//    
//    override func layoutSubviews() {
//        self.center = startingPoint!////////if first
//        super.layoutSubviews()
//    }
}
