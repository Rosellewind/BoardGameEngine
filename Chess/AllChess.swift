//
//  AllChess.swift
//  Chess
//
//  Created by Roselle Milvich on 6/13/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

// basic Game class
// make board, view

//subclass or class func
// make chessboard, view, override init but nothing else
// init(chessgame/options)


private enum ChessLegalIfCondition: Int {
    case RookCanCastle = 1000, CantBeInCheckDuring
}

enum ChessVariation: Int {
    case StandardChess, GalaxyChess
}

enum TurnCondition {
    case CantExposeKing
}

enum PlayerOrientation: Int {
    case bottom, top, left, right
    func color() -> String {
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
    func defaultColor() -> String {
        return "White"
    }
}

enum ChessPiece: String {
    case King, Queen, Rook, Bishop, Knight, Pawn
}

class ChessGame: Game {
    init(chessVariation: ChessVariation, gameView: UIView) {
        
        // create the board
        let chessBoard = Board(numRows: 8, numColumns: 8)
        
        // create the boardView
        let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.redColor(), UIColor.blackColor()])
        
        // create the players with pieces
        let chessPlayers = [ChessPlayer(index: 0), ChessPlayer(index: 1)]
        

        // create pieceView's
        var chessPieceViews = [PieceView]()
        for player in chessPlayers {
            for piece in player.pieces {
                if let image = UIImage(named: piece.name + (player.name ?? "")) {
                    let pieceView = PieceView(image: image, pieceTag: piece.tag)
                    chessPieceViews.append(pieceView)
                }
            }
        }
        
        super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers, pieceViews: chessPieceViews)

        // chessVariation rules
        switch chessVariation {
        case .StandardChess:
            // add turn conditions
            turnConditions = [.CantExposeKing]////////change to moveConditions?
        default:
            break
        }
    }
    
    override func pieceConditionsAreMet(piece: Piece, player: Player, conditions: [(condition: Int, positions: [Position]?)]?) -> Bool {
        var conditionsAreMet = super.pieceConditionsAreMet(piece, player: player, conditions: conditions)
        for condition in conditions ?? [] where conditionsAreMet == true {
            if let chessLegalIfCondition = ChessLegalIfCondition(rawValue:condition.condition) {
                switch chessLegalIfCondition {                case .RookCanCastle://///king?////test
                    let rooks = player.pieces.filter({$0.name.hasPrefix("Rook")})
                    var castlingRook: Piece?
                    var rookLandingSpot: Position
                    if let king = player.pieces.elementPassing({$0.name == "King"}) {
                        for rook in rooks where castlingRook == nil {
                            if rook.isFirstMove {
                                for translation in condition.positions ?? []  where castlingRook == nil  {
                                    let position = positionFromTranslation(translation, fromPosition: king.position, direction: player.forwardDirection)
                                    let translation = calculateTranslation(rook.position, toPosition: position, direction: player.forwardDirection)
                                    let moveFunction = rook.isLegalMove(translation: translation)
                                    if pieceConditionsAreMet(rook, player: player, conditions: moveFunction.conditions) {
                                        castlingRook = rook
                                        let rookOffset = position.column < rook.position.column ? -1 : 1
                                        rookLandingSpot = Position(row: position.row, column: position.column + rookOffset)
                                    }
                                }
                            }
                        }
                    }
                    if castlingRook != nil {
                        ////****move rook to rookLandingSpot
                        //                    let completionBlock = move(rook, rookLandingSpot)
                    } else {
                        conditionsAreMet = false
                    }
                case .CantBeInCheckDuring:////test
                    ////temp
                    if isCheck(player) {
                        conditionsAreMet = false
                    }
                    
                    
                    //                for translation in condition.positions {
                    //
                    //                }
                    break////****implement
                }
            }
        }
        return conditionsAreMet
    }
    
    override func turnConditionsAreMet(conditions: [TurnCondition]?) -> Bool {
        var conditionsAreMet = super.turnConditionsAreMet(conditions)
        for condition in conditions ?? [] {
            switch condition {
            case .CantExposeKing:
                if let king = players[whoseTurn].pieces.elementPassing({$0.name == "King"}) {
                    // for every opponents piece in new positions, can king be taken?
                    for piece in players[nextTurn].pieces where conditionsAreMet == true {
                        let translation = calculateTranslation(piece.position, toPosition: king.position, direction: players[nextTurn].forwardDirection)
                        let moveFunction = piece.isLegalMove(translation: translation)
                        if moveFunction.isLegal && pieceConditionsAreMet(piece, player: players[nextTurn], conditions: moveFunction.conditions){
                            conditionsAreMet = false
                        }
                    }
                }
            }
            
        }
        return conditionsAreMet
    }
    
    override func gameOver() -> Bool {
        for player in players {
            if isCheckMate(player) {
                statusDelegate?.gameMessage((player.name ?? "") + " Is In Checkmate!!!", status: .GameOver)
                return true
            }
        }
        return false
    }
    
    func isCheck(player: Player) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        if let king = player.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in players where isCheck == false {
                if otherPlayer === player {
                    continue
                } else {
                    for piece in otherPlayer.pieces where isCheck == false {
                        let translation = calculateTranslation(piece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = piece.isLegalMove(translation: translation)
                        isCheck = moveFunction.isLegal && pieceConditionsAreMet(piece, player: otherPlayer, conditions: moveFunction.conditions)
                    }
                }
            }
        }
        print("\(player.name) is in Check: \(isCheck)")
        return isCheck
    }
    
    func isCheckMate(player: Player) -> Bool {
        var isCheckMate = true
        let otherPlayers = players.filter({$0 !== player})
        if let king = player.pieces.elementPassing({$0.name == "King"}) {
            var positionsToCheck = [Position(row: king.position.row - 1, column: king.position.column - 1),
                                    Position(row: king.position.row - 1, column: king.position.column),
                                    Position(row: king.position.row - 1, column: king.position.column + 1),
                                    Position(row: king.position.row, column: king.position.column - 1),
                                    Position(row: king.position.row, column: king.position.column),
                                    Position(row: king.position.row, column: king.position.column + 1),
                                    Position(row: king.position.row + 1, column: king.position.column - 1),
                                    Position(row: king.position.row + 1, column: king.position.column),
                                    Position(row: king.position.row + 1, column: king.position.column + 1)]
            // trim positions that are off the board
            positionsToCheck = positionsToCheck.filter({$0.row >= 0 && $0.row < board.numRows})
            
            // trim positions that are already occupied   ////castling/otherrules?
            positionsToCheck = positionsToCheck.filter({pieceForPosition($0) == nil})
            if positionsToCheck.count > 0 {
                for position in positionsToCheck where isCheckMate == true {
                    var positionIsSafe = true
                    for otherPlayer in otherPlayers where positionIsSafe == true {
                        for piece in otherPlayer.pieces where positionIsSafe == true {
                            let translation = calculateTranslation(piece.position, toPosition: position, direction: otherPlayer.forwardDirection)
                            let moveFunction = piece.isLegalMove(translation: translation)
                            positionIsSafe = !(moveFunction.isLegal && pieceConditionsAreMet(piece, player: otherPlayer, conditions: moveFunction.conditions))
                        }
                    }
                    if positionIsSafe {
                        isCheckMate = false
                    }
                }
            } else {
                isCheckMate = false
            }
            
        }
        print("\(player.name) is in checkmate: \(isCheckMate)")
        
        return isCheckMate
    }
}


class ChessPlayer: Player {
    var orientation: PlayerOrientation {
        return PlayerOrientation(rawValue: self.index) ?? PlayerOrientation.bottom
    }
    init(index: Int) {
        let pieces = ChessPieceCreator.sharedInstance.makePieces(ChessVariation.StandardChess.rawValue, playerId: index)
        super.init(name: nil, index: index, forwardDirection: nil, pieces: pieces)
        self.name = self.orientation.color()
    }
}

class ChessPieceCreator: PiecesCreator {
    static let sharedInstance = ChessPieceCreator()
    func makePieces(variation: ChessVariation.RawValue, playerId: Int) -> [Piece] {
        let position = PlayerOrientation(rawValue: playerId) ?? PlayerOrientation.bottom
        var pieces = [Piece]()
        switch ChessVariation(rawValue: variation) ?? ChessVariation.StandardChess {
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
            
            pieces.appendContentsOf(royalty)
            pieces.appendContentsOf(pawns)
            
        case .GalaxyChess:
            let piece = Piece(name: "ship", position: Position(row: 3, column: 3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                return (true, nil)
            })
            pieces.append(piece)
        }
        
        // set the tag
        let offset = position.rawValue * pieces.count
        for i in 0..<pieces.count {
            pieces[i].tag = i + offset
        }
        return pieces
    }
    
    func chessPiece(name: ChessPiece) -> Piece {
        switch name {
        case .King:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 4), isLegalMove: {(translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: Int, positions: [Position]?)]?
                
                // exactly one square horizontally, vertically, or diagonally, 1 castling per game
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if (translation.row == 0 || translation.row == -1 || translation.row == 1) && (translation.column == 0 || translation.column == -1 || translation.column == 1){
                    isLegal = true
                    conditions = [(LegalIfCondition.CantBeOccupiedBySelf.rawValue, [translation])]
                } else if translation.row == 0 && abs(translation.column) ==  2 {
                    // Castling:
                    // 1. neither king nor rook has moved
                    // 2. there are no pieces between king and rook
                    // 3. "One may not castle out of, through, or into check."
                    // into check is already being checked///////////every piece have can't go into check? do I need turn conditions?
                    let signage = translation.column > 0 ? 1 : -1
                    isLegal = true
                    conditions = [(LegalIfCondition.IsInitialMove.rawValue, nil), (ChessLegalIfCondition.RookCanCastle.rawValue, [translation]), (LegalIfCondition.CantBeOccupied.rawValue,[translation, Position(row: translation.row, column: (abs(translation.column) - 1) * signage)]), (ChessLegalIfCondition.CantBeInCheckDuring.rawValue, [Position(row: 0, column: 0), Position(row:0, column: (abs(translation.column) - 1) * signage), translation])]
                }
                return (isLegal, conditions)
            })
        case .Queen:
            return Piece(name: name.rawValue, position: Position(row: 0, column:  3), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.CantBeOccupiedBySelf.rawValue, positions: [translation])]
                
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
                    conditions.append((LegalIfCondition.CantBeOccupied.rawValue, cantBeOccupied))
                }
                return (isLegal, conditions)
            })
        case .Rook:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.CantBeOccupiedBySelf.rawValue, positions: [translation])]
                
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
                    conditions.append((LegalIfCondition.CantBeOccupied.rawValue, cantBeOccupied))
                }
                return (isLegal, conditions)
            })
        case .Bishop:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 2), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                
                // can't land on self
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.CantBeOccupiedBySelf.rawValue, positions: [translation])]
                
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
                    conditions.append((LegalIfCondition.CantBeOccupied.rawValue, cantBeOccupied))
                }
                return (isLegal, conditions)
            })
        case .Knight:
            return Piece(name: name.rawValue, position: Position(row: 0, column: 1), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: Int, positions: [Position]?)]?
                
                // the nearest square not on the same rank, file, or diagonal, L, 2 steps/1 step
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == 2 && abs(translation.column) == 1 || abs(translation.row) == 1 && abs(translation.column) == 2{
                    isLegal = true
                    conditions = [(LegalIfCondition.CantBeOccupiedBySelf.rawValue, [translation])]
                }
                return (isLegal, conditions)
            })
            
        case .Pawn:
            let piece = Piece(name: name.rawValue, position: Position(row: 1, column: 0), isLegalMove: { (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: Int, positions: [Position]?)]?
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 2 && translation.column == 0 {  // initial move, forward two
                    isLegal = true
                    conditions = [(LegalIfCondition.CantBeOccupied.rawValue, [Position(row: 1, column: 0), Position(row: 2, column: 0)]), (LegalIfCondition.IsInitialMove.rawValue, nil)]
                    return (isLegal, conditions)
                } else if translation.row == 1 && translation.column == 0 {     // move forward one on vacant
                    isLegal = true
                    conditions = [(LegalIfCondition.CantBeOccupied.rawValue, [translation])]
                } else if translation.row == 1 && abs(translation.column) == 1 {    // move diagonal one on occupied
                    isLegal = true
                    conditions = [(LegalIfCondition.MustBeOccupiedByOpponent.rawValue, [translation])]
                }
                return (isLegal, conditions)
            })
            return piece
        }}
    }











