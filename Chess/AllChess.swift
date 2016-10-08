//
//  AllChess.swift
//  Chess
//
//  Created by Roselle Milvich on 6/13/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


enum ChessVariation: Int {
    case standardChess, galaxyChess
}

private enum ChessLegalIfCondition: Int {
    case cantBeInCheckDuring = 1000, rookCanCastle, markAdvancedTwo, mustBeOccupiedByOpponentOrEnPassant, checkForPromotion
}

private enum ChessTurnCondition: Int {
    case cantExposeKing = 1000
}

private enum PlayerOrientation: Int {
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

private enum ChessPieceType: String {
    case King, Queen, Rook, Bishop, Knight, Pawn
}

class ChessPiece: Piece {////PawnPiece?
    var roundWhenPawnAdvancedTwo: Int?
}

class ChessGame: Game {
    init(chessVariation: ChessVariation, gameView: UIView) {
        
        // create the board
        let chessBoard = Board(numRows: 8, numColumns: 8)
        
        // create the boardView
        let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
        
        // create the players with pieces
        let chessPlayers = [ChessPlayer(index: 0), ChessPlayer(index: 1)]
        
        super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)

//        // chessVariation rules
//        switch chessVariation {
//        case .standardChess:
//            // add turn conditions
//            turnConditions = [ChessTurnCondition.cantExposeKing.rawValue]
//        default:
//            break
//        }
    }
    
    override func pieceConditionsAreMet(_ piece: Piece, conditions: [(condition: Int, positions: [Position]?)]?, snapshot: GameSnapshot?) -> (isMet: Bool, completions: [(() -> Void)]?) {////go through conditions sequentially, change from checking all Game conditions first
        let pieceInSnapshot = snapshot?.allPieces.elementPassing({$0.id == piece.id})
        let thisPiece = pieceInSnapshot ?? piece
        let superConditionsAreMet = super.pieceConditionsAreMet(thisPiece, conditions: conditions, snapshot: snapshot)
        var isMet = superConditionsAreMet.isMet
        var completions = superConditionsAreMet.completions ?? Array<()->Void>()

        if let player = thisPiece.player {
            for condition in conditions ?? [] where isMet == true {
                if let chessLegalIfCondition = ChessLegalIfCondition(rawValue:condition.condition) {
                    switch chessLegalIfCondition {
                    case .rookCanCastle:
                        // king moves 2 horizontally, rook goes where king just crossed
                        // 1. neither the king nor the rook may have been previously moved
                        // 2. there must not be pieces between the king and rook
                        // 3. the king may not be in check, nor may the king pass through squares athat are under attack by eney pieces, nor move to a square where it is in check
                        //////stopped here, pass though check
                        
                        
                        // rules needing to be checked here:
                        //      rook can't be previously moved
                        //      can't be occupied to rook landing spot(isLegalMove/pieceConditionsAreMet)
                        // also verify:
                        //      CantBeInCheckDuring[0,0][0, abs-1]
                        //  still need:
                        //      king can't have moved before
                        
                        let rooks = player.pieces.filter({$0.name.hasPrefix("Rook")})
                        var castlingRooks = [Piece]()
                        var landingPositionForRook = Position(row: 0, column: 0)
                        if let king = player.pieces.elementPassing({$0.name == "King"}) {
                            for rook in rooks {
                                
                                // checks half of rule 1, rook can't be previously moved
                                if rook.isFirstMove {
                                    
                                    if let rookLandingTranslationRelativeToKing = condition.positions?[0] {
                                        
                                        // checks half of rule 2, can't be pieces between rook and where rook is landing OR between the rook and king if rook crosses past kings initial position
                                        var translation: Position
                                        landingPositionForRook = positionFromTranslation(rookLandingTranslationRelativeToKing, fromPosition: king.position, direction: player.forwardDirection)
                                        
                                        let startingSide = king.position.column - rook.position.column < 0 ? -1 : 1
                                        let endingSide = king.position.column - landingPositionForRook.column < 0 ? -1 : 1
                                        let rookCrossesKing = startingSide != endingSide
                                        if rookCrossesKing {
                                            let positionOneBackFromKing = Position(row: king.position.row, column: king.position.column + endingSide)
                                            translation = calculateTranslation(rook.position, toPosition: positionOneBackFromKing, direction: player.forwardDirection)
                                        } else {
                                            translation = calculateTranslation(rook.position, toPosition: landingPositionForRook, direction: player.forwardDirection)
                                            
                                        }
                                        let moveFunction = rook.isLegalMove(translation)
                                        if pieceConditionsAreMet(rook, conditions: moveFunction.conditions, snapshot: snapshot).isMet {
                                            castlingRooks.append(rook)
                                        }
                                    }
                                }
                            }
                        }
                        if castlingRooks.count == 0 {
                            isMet = false
                        } else {
                            // move the rook
                            
                            
                            let completion: () -> Void = { self.moveARook(castlingRooks, position: landingPositionForRook)}
                            completions.append(completion)
                            isMet = true
                        }
                        
                    case .cantBeInCheckDuring:
                        for translation in condition.positions ?? [] {
                            
                            // move in snapshot
                            reusableGameSnapshot = GameSnapshot(game: self)
                            if let thisPlayer = thisPiece.player {
                                let position = positionFromTranslation(translation, fromPosition: thisPiece.position, direction: thisPlayer.forwardDirection)
                                makeMoveInSnapshot(Move(piece: thisPiece, remove: false, position: position), snapshot: reusableGameSnapshot!)
                                if isCheck(player, snapshot: reusableGameSnapshot) {
                                    print("IsInCheckDuring is true")
                                    isMet = false
                                }
                            }
                        }
                    case .markAdvancedTwo:
                        let completion: () -> Void = {(piece as? ChessPiece)?.roundWhenPawnAdvancedTwo = self.round}
                        completions.append(completion)
                        isMet = true
                    
                    case .mustBeOccupiedByOpponentOrEnPassant:
                        if let positions = condition.positions {
                            if positions.count == 2 {
                                let landingPosition = positions[0]
                                let occupiedCondition = super.pieceConditionsAreMet(piece, conditions: [(condition: LegalIfCondition.mustBeOccupiedByOpponent.rawValue, positions: [landingPosition])], snapshot: nil)
                                
                                var enPassantPawn: ChessPiece? = nil
                                let enPassantPosition = positionFromTranslation(positions[1], fromPosition: thisPiece.position, direction: player.forwardDirection)
                                if let possiblePawn = pieceForPosition(enPassantPosition, snapshot: nil) as? ChessPiece {
                                    if let roundWhenPawnAdvancedTwo = possiblePawn.roundWhenPawnAdvancedTwo {
                                        if let pawnIndex = playerIndex(player: player) {
                                            if let enPassantPlayer = possiblePawn.player {
                                                if let enPassantIndex = playerIndex(player: enPassantPlayer) {
                                                    if pawnIndex != enPassantIndex {
                                                        let isBetween = pawnIndex.isBetweenInForwardLoop(firstInclusive: firstInRound, lastNotInclusive: enPassantIndex)
                                                        let isStillFirstRoundSinceAdvancedTwo = (isBetween && round == roundWhenPawnAdvancedTwo + 1) || (!isBetween && round == roundWhenPawnAdvancedTwo)
                                                        if isStillFirstRoundSinceAdvancedTwo {
                                                            enPassantPawn = possiblePawn
                                                        }
                                                    }
                                                }
                                            }
    
                                        }
                                    }
                                }
                                if occupiedCondition.completions != nil{
                                    completions += occupiedCondition.completions!
                                }
                                
                                if enPassantPawn != nil {
                                    let enPassantCompletion: () -> Void = {self.removePieceAndViewFromGame(piece: enPassantPawn!)}
                                    completions.append(enPassantCompletion)
                                    isMet = true
                                } else {
                                    isMet = occupiedCondition.isMet
                                }
                            }
                        }
                    case .checkForPromotion:
                        let checkPromotionCompletion: () -> Void = {
                            if let direction = piece.player?.forwardDirection {
                                var hasReachedEighthRank = false
                                switch direction {
                                case .bottom:
                                    hasReachedEighthRank = piece.position.row == self.board.numRows - 1
                                case .left:
                                    hasReachedEighthRank = piece.position.column == 0
                                case .right:
                                    hasReachedEighthRank = piece.position.column == self.board.numColumns - 1
                                case .top:
                                    hasReachedEighthRank = piece.position.row == 0
                                }
                                if hasReachedEighthRank {
                                    // have the presenting VC ask what promotion they want
                                    let alert = UIAlertController(title: "Promotion", message: "Which chess piece do you want to promote your pawn with?", preferredStyle: .actionSheet)
                                    let queen = UIAlertAction(title: "Queen", style: .default, handler: {(UIAction) in
                                        self.promote(piece: piece, toType: .Queen)
                                        alert.dismiss(animated: true, completion: nil)
                                    })
                                    alert.addAction(queen)
                                    let knight = UIAlertAction(title: "Knight", style: .default, handler: {(UIAction) in
                                        self.promote(piece: piece, toType: .Knight)
                                        alert.dismiss(animated: true, completion: nil)
                                    })
                                    alert.addAction(knight)
                                    let rook = UIAlertAction(title: "Rook", style: .default, handler: {(UIAction) in
                                        self.promote(piece: piece, toType: .Rook)
                                        alert.dismiss(animated: true, completion: nil)
                                    })
                                    alert.addAction(rook)
                                    let bishop = UIAlertAction(title: "Bishop", style: .default, handler: {(UIAction) in
                                        self.promote(piece: piece, toType: .Bishop)
                                        alert.dismiss(animated: true, completion: nil)
                                    })
                                    alert.addAction(bishop)                                    
                                    self.presenterDelegate?.showAlert(alert)
                                }
                            }
                        }
                        completions.append(checkPromotionCompletion)
                        isMet = true
                    }
                }
            }
        }
        
        if isMet == false || completions.count == 0 {
            return (isMet, nil)
        } else {
            return (isMet, completions)
        }
    }
    
    func moveARook(_ rooks: [Piece], position: Position) {
        if rooks.count == 2 {
            
            // find the direction the player is moving
            var playerOrientation = PlayerOrientation.bottom
            if let player = rooks[0].player as? ChessPlayer {
                playerOrientation = player.orientation
            }
            
            // have the presenting VC ask which rook to use
            let alert = UIAlertController(title: "Castling", message: "Which rook do you want to use?", preferredStyle: .alert)
            let leftAction = UIAlertAction(title: "Left", style: .default, handler: { (action: UIAlertAction) in
                let leftRook: Piece
                switch playerOrientation {
                case .bottom:
                    leftRook = rooks[0].position.column < rooks[1].position.column ? rooks[0] : rooks[1]
                case .top:
                    leftRook = rooks[0].position.column > rooks[1].position.column ? rooks[0] : rooks[1]
                case .left:
                    leftRook = rooks[0].position.row < rooks[1].position.row ? rooks[0] : rooks[1]
                case .right:
                    leftRook = rooks[0].position.row > rooks[1].position.row ? rooks[0] : rooks[1]
                }
                self.makeMove(Move(piece: leftRook, remove: false, position: position))
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(leftAction)
            let rightAction = UIAlertAction(title: "Right", style: .default, handler: { (action: UIAlertAction) in
                let rightRook: Piece
                switch playerOrientation {
                case .bottom:
                    rightRook = rooks[0].position.column > rooks[1].position.column ? rooks[0] : rooks[1]
                case .top:
                    rightRook = rooks[0].position.column < rooks[1].position.column ? rooks[0] : rooks[1]
                case .left:
                    rightRook = rooks[0].position.row > rooks[1].position.row ? rooks[0] : rooks[1]
                case .right:
                    rightRook = rooks[0].position.row < rooks[1].position.row ? rooks[0] : rooks[1]
                }
                self.makeMove(Move(piece: rightRook, remove: false, position: position))
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(rightAction)
            presenterDelegate?.showAlert(alert)
        } else if rooks.count == 1 {
            self.makeMove(Move(piece: rooks[0], remove: false, position: position))
        }
    }
    
//    override func turnConditionsAreMet(_ conditions: [TurnCondition.RawValue]?, snapshot: GameSnapshot?) -> Bool {
//        var conditionsAreMet = super.turnConditionsAreMet(conditions, snapshot: snapshot)
//        let thisPlayers = snapshot?.players ?? players
//        let thisWhoseTurn = snapshot?.whoseTurn ?? whoseTurn
//        let thisNextTurn = snapshot?.nextTurn ?? nextTurn
//        for condition in conditions ?? [] where conditionsAreMet == true {
//            if let chessTurnCondition =  ChessTurnCondition(rawValue: condition) {
//                switch chessTurnCondition {
//                case .cantExposeKing:
//                    if let king = thisPlayers[thisWhoseTurn].pieces.elementPassing({$0.name == "King"}) {
//                        // for every opponents piece in new positions, can king be taken?
//                        for nextPlayersPiece in thisPlayers[thisNextTurn].pieces where conditionsAreMet == true {
//                            let translation = calculateTranslation(nextPlayersPiece.position, toPosition: king.position, direction: thisPlayers[thisNextTurn].forwardDirection)
//                            let moveFunction = nextPlayersPiece.isLegalMove(translation)
//                            if moveFunction.isLegal && pieceConditionsAreMet(nextPlayersPiece, conditions: moveFunction.conditions, snapshot: snapshot).isMet{
//                                conditionsAreMet = false
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        return conditionsAreMet
//    }
    
    override func gameOver() -> Bool {
        for player in players {
            if isCheckMate(player, snapshot: nil) {
                presenterDelegate?.gameMessage((player.name ?? "") + " Is In Checkmate!!!", status: .gameOver)
                return true
            }
        }
        return false
    }
    
    func isCheck(_ player: Player, snapshot: GameSnapshot?) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        let thisPlayer = snapshot?.players.elementPassing({$0.id == player.id}) ?? player
        let thisPlayers = snapshot?.players ?? players
        if let king = thisPlayer.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in thisPlayers where isCheck == false {
                if otherPlayer === thisPlayer {
                    continue
                } else {
                    for otherPlayerPiece in otherPlayer.pieces where isCheck == false {
                        let translation = calculateTranslation(otherPlayerPiece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = otherPlayerPiece.isLegalMove(translation)
                        isCheck = moveFunction.isLegal && pieceConditionsAreMet(otherPlayerPiece, conditions: moveFunction.conditions, snapshot: snapshot).isMet
                    }
                }
            }
        }
        print("\(thisPlayer.name) is in Check: \(isCheck)")
        return isCheck
    }
    // midTurn, between moves,
    func isCheckMate(_ player: Player, snapshot: GameSnapshot?) -> Bool {////is being called twice, once for each player
        
        var isCheckMate = true
        if !isCheck(player, snapshot: snapshot) {
            isCheckMate = false
        } else {
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
                
                // trim positions that are already occupied
                positionsToCheck = positionsToCheck.filter({pieceForPosition($0, snapshot: nil) == nil})
                if positionsToCheck.count > 0 {
                    for position in positionsToCheck where isCheckMate == true {
                        var positionIsSafe = true
                        for otherPlayer in otherPlayers where positionIsSafe == true {
                            for otherPlayersPiece in otherPlayer.pieces where positionIsSafe == true {
                                let translation = calculateTranslation(otherPlayersPiece.position, toPosition: position, direction: otherPlayer.forwardDirection)
                                let moveFunction = otherPlayersPiece.isLegalMove(translation)
                                positionIsSafe = !(moveFunction.isLegal && pieceConditionsAreMet(otherPlayersPiece, conditions: moveFunction.conditions, snapshot: snapshot).isMet)
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
        }
        return isCheckMate
    }
    
    fileprivate func promote(piece: Piece, toType: ChessPieceType) {
        // create replacement
        let newPiece = ChessPieceCreator.shared.chessPiece(toType)
        newPiece.position = piece.position
        newPiece.id = piece.id
        newPiece.isFirstMove = piece.isFirstMove
        newPiece.startingPosition = piece.startingPosition
        newPiece.player = piece.player
        newPiece.selected = piece.selected
        
        // remove the old and add the new
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
            self.removePieceAndViewFromGame(piece: piece)
            self.addPieceAndViewToGame(piece: newPiece)
            }, completion: nil)
//        UIView.animate(withDuration: 0.2, animations: removePieceAndViewFromGame(piece: piece)
//            addPieceAndViewToGame(piece: newPiece))
        
    }
}


class ChessPlayer: Player {
    fileprivate var orientation: PlayerOrientation {
        return PlayerOrientation(rawValue: self.id) ?? PlayerOrientation.bottom
    }
    init(index: Int) {
        let pieces = ChessPieceCreator.shared.makePieces(ChessVariation.standardChess.rawValue, playerId: index)
        super.init(name: nil, id: index, forwardDirection: nil, pieces: pieces)
        self.name = self.orientation.color()
    }
}

class ChessPieceCreator: PiecesCreator {
    static let shared = ChessPieceCreator()
    func makePieces(_ variation: ChessVariation.RawValue, playerId: Int) -> [Piece] {
        let position = PlayerOrientation(rawValue: playerId) ?? PlayerOrientation.bottom
        var pieces = [Piece]()
        switch ChessVariation(rawValue: variation) ?? ChessVariation.standardChess {
        case .standardChess:
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
            let piece = Piece(name: "ship", position: Position(row: 3, column: 3), isLegalMove: { IsLegalMove in
                return (true, nil)
            })
            pieces.append(piece)
        }
        
        // set the id and isFirstMove
        let offset = position.rawValue * pieces.count
        for i in 0..<pieces.count {
            pieces[i].id = i + offset
            pieces[i].isFirstMove = true
        }
        return pieces
    }
    
    fileprivate func chessPiece(_ name: ChessPieceType) -> ChessPiece {
        switch name {
        case .King:
            return ChessPiece(name: name.rawValue, position: Position(row: 0, column: 4), isLegalMove: {(translation: Translation) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition.RawValue, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [translation])]
                
                // exactly one square horizontally, vertically, or diagonally, 1 castling per game
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if (translation.row == 0 || translation.row == -1 || translation.row == 1) && (translation.column == 0 || translation.column == -1 || translation.column == 1){
                    isLegal = true
                    conditions.append((LegalIfCondition.cantBeOccupiedBySelf.rawValue, [translation]))
                } else if translation.row == 0 && abs(translation.column) ==  2 {
                    // Castling:
                    // 1. neither king nor rook has moved
                    // 2. there are no pieces between king and rook
                    // 3. "One may not castle out of, through, or into check." (rook can be under attack, just not the king)

                    let signage = translation.column > 0 ? 1 : -1
                    isLegal = true
                    // checked here: king.isInitialMove, RookCanCastle[translation], no pieces inbetween king and landing spot, CantBeInCheckDuring[0,0][0, abs-1]
//                    let condition: [(condition: Int, positions: [Position]?)] = [(LegalIfCondition.isInitialMove.rawValue, nil), (ChessLegalIfCondition.rookCanCastle.rawValue, [Position(row: 0, column: signage)]), (LegalIfCondition.cantBeOccupied.rawValue,[translation, Position(row: translation.row, column: (abs(translation.column) - 1) * signage)]), (ChessLegalIfCondition.cantBeInCheckDuring.rawValue, [Position(row: 0, column: 0), Position(row:0, column: (abs(translation.column) - 1) * signage), translation])]
                    
                    let moreConditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.isInitialMove.rawValue, positions: nil), (condition: ChessLegalIfCondition.rookCanCastle.rawValue, positions: [Position(row: 0, column: signage)]), (condition: LegalIfCondition.cantBeOccupied.rawValue, positions: [translation, Position(row: translation.row, column: (abs(translation.column) - 1) * signage)]), (condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [Position(row: 0, column: 0), Position(row:0, column: (abs(translation.column) - 1) * signage), translation])]
                    conditions += moreConditions
                }
                return (isLegal, conditions)
            })
        case .Queen:
            return ChessPiece(name: name.rawValue, position: Position(row: 0, column:  3), isLegalMove: { (translation: Translation) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition.RawValue, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.cantBeOccupiedBySelf.rawValue, positions: [translation])]
                
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
                    conditions.append((LegalIfCondition.cantBeOccupied.rawValue, cantBeOccupied))
                }
                conditions.append((condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [translation]))
                return (isLegal, conditions)
            })
        case .Rook:
            return ChessPiece(name: name.rawValue, position: Position(row: 0, column: 0), isLegalMove: { (translation: Translation) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.cantBeOccupiedBySelf.rawValue, positions: [translation])]
                
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
                    conditions.append((LegalIfCondition.cantBeOccupied.rawValue, cantBeOccupied))
                }
                conditions.append((condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [translation]))
                return (isLegal, conditions)
            })
        case .Bishop:
            return ChessPiece(name: name.rawValue, position: Position(row: 0, column: 2), isLegalMove: { (translation: Translation) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var cantBeOccupied = [Position]()
                
                // can't land on self or leave self in check
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: LegalIfCondition.cantBeOccupiedBySelf.rawValue, positions: [translation])]
                
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
                    conditions.append((LegalIfCondition.cantBeOccupied.rawValue, cantBeOccupied))
                }
                conditions.append((condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [translation]))
                return (isLegal, conditions)
            })
        case .Knight:
            return ChessPiece(name: name.rawValue, position: Position(row: 0, column: 1), isLegalMove: { (translation: Translation) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: Int, positions: [Position]?)]?
                
                // the nearest square not on the same rank, file, or diagonal, L, 2 steps/1 step
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if abs(translation.row) == 2 && abs(translation.column) == 1 || abs(translation.row) == 1 && abs(translation.column) == 2{
                    isLegal = true
                    conditions = [(LegalIfCondition.cantBeOccupiedBySelf.rawValue, [translation]), (condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [translation])]
                }
                return (isLegal, conditions)
            })
            
        case .Pawn:
            let piece = ChessPiece(name: name.rawValue, position: Position(row: 1, column: 0), isLegalMove: { (translation: Translation) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?) in
                var isLegal = false
                var conditions: [(condition: Int, positions: [Position]?)] = [(condition: ChessLegalIfCondition.checkForPromotion.rawValue, positions: nil)]
                
                if translation.row == 0 && translation.column == 0 {
                    isLegal = false
                } else if translation.row == 2 && translation.column == 0 {  // initial move, forward two
                    isLegal = true
                    conditions.append((condition: LegalIfCondition.isInitialMove.rawValue, positions: nil))
                    conditions.append((condition: LegalIfCondition.cantBeOccupied.rawValue, positions: [Position(row: 1, column: 0), Position(row: 2, column: 0)]))
                    conditions.append((condition: ChessLegalIfCondition.markAdvancedTwo.rawValue, positions: nil))
                } else if translation.row == 1 && translation.column == 0 {     // move forward one on vacant
                    isLegal = true
                    conditions.append((LegalIfCondition.cantBeOccupied.rawValue, [translation]))
                } else if translation.row == 1 && abs(translation.column) == 1 {    // move diagonal one on occupied
                    isLegal = true
                    conditions.append((ChessLegalIfCondition.mustBeOccupiedByOpponentOrEnPassant.rawValue, [translation, Translation(row: 0, column:translation.column)]))
                }
                conditions.append((condition: ChessLegalIfCondition.cantBeInCheckDuring.rawValue, positions: [translation]))
                return (isLegal, conditions)
            })
            return piece
        }}
    }











