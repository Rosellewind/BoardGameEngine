//
//  AllChess.swift
//  ChessGame
//
//  Created by Roselle Milvich on 6/13/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


enum ChessVariation: Int {
    case standardChess, fourPlayer, galaxyChess
}

class ChessGame: Game {
    init(chessVariation: ChessVariation, gameView: UIView) {
        switch chessVariation {
        case .fourPlayer:

            // create the board
            let chessBoard = Board(numRows: 12, numColumns: 12, skipCells: [0, 1 ,10, 11, 12, 13, 22, 23, 120, 121, 130, 131, 132, 133, 142, 143])
            
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation.rawValue), ChessPlayer(index: 1, variation: chessVariation.rawValue), ChessPlayer(index: 2, variation: chessVariation.rawValue), ChessPlayer(index: 3, variation: chessVariation.rawValue)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
            
        default:
            
            // create the board
            let chessBoard = Board(numRows: 8, numColumns: 8)
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation.rawValue), ChessPlayer(index: 1, variation: chessVariation.rawValue)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)        }

    }
    
    override func pieceConditionsAreMet(_ piece: Piece, conditions: [(condition: Int, translations: [Translation]?)]?, snapshot: GameSnapshot?) -> (isMet: Bool, completions: [(() -> Void)]?) {////go through conditions sequentially, change from checking all Game conditions first
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
                                    
                                    if let rookLandingTranslationRelativeToKing = condition.translations?[0] {
                                        
                                        // checks half of rule 2, can't be pieces between rook and where rook is landing OR between the rook and king if rook crosses past kings initial position
                                        var translation: Translation
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
                        for translation in condition.translations ?? [] {
                            
                            // move in snapshot
                            reusableGameSnapshot = GameSnapshot(game: self)
                            if let thisPlayer = thisPiece.player {
                                let position = positionFromTranslation(translation, fromPosition: thisPiece.position, direction: thisPlayer.forwardDirection)
                                makeMoveInSnapshot(Move(piece: thisPiece, remove: false, position: position), snapshot: reusableGameSnapshot!)
                                if isCheck(player, snapshot: reusableGameSnapshot) {
                                    isMet = false
                                }
                            }
                        }
                    case .markAdvancedTwo:
                        let completion: () -> Void = {(piece as? PawnPiece)?.roundWhenPawnAdvancedTwo = self.round}
                        completions.append(completion)
                        isMet = true
                    
                    case .mustBeOccupiedByOpponentOrEnPassant:
                        if let translations = condition.translations {
                            if translations.count == 2 {
                                let landingTranslation = translations[0]
                                let occupiedCondition = super.pieceConditionsAreMet(piece, conditions: [(condition: LegalIfCondition.mustBeOccupiedByOpponent.rawValue, translations: [landingTranslation])], snapshot: nil)
                                
                                var enPassantPawn: PawnPiece? = nil
                                let enPassantPosition = positionFromTranslation(translations[1], fromPosition: thisPiece.position, direction: player.forwardDirection)
                                if let possiblePawn = pieceForPosition(enPassantPosition, snapshot: nil) as? PawnPiece {
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
            var playerOrientation = ChessPlayerOrientation.bottom
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
    
    override func checkForGameOver(){
        let player = players[whoseTurn]
        if isCheck(player, snapshot: nil) {
            let message = player.name != nil ? (player.name! + " is in check") : "in check"
            presenterDelegate?.secondaryGameMessage(string: message)
        } else {
            presenterDelegate?.secondaryGameMessage(string: "")
        }
        var playersInCheckMate = [Player]()
        for player in players {
            if player.id != players[whoseTurn].id {
                if isCheckMate(player, snapshot: nil) {
                    playersInCheckMate.append(player)
                }
            }
        }
        if playersInCheckMate.count > 0 {
            var message = (player.name ?? "")
            if playersInCheckMate.count == 1 {
                message.append(" Is In Checkmate!!!")
            } else {
                for player in playersInCheckMate {
                    message.append(" And ")
                    message.append(player.name ?? "")
                    message.append(" Are In Checkmate!!!")
                }
            }
            presenterDelegate?.gameMessage(message, status: .gameOver)
        }
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
        return isCheck
    }
    // midTurn, between moves,
    func isCheckMate(_ player: Player, snapshot: GameSnapshot?) -> Bool {
        
        // after a move, check next player for checkmate if in check
        // if in check, can use any piece to get out of check?
//        if snapshot.isCheck
//        check all translations pieces can move
        var isCheckMate = false
        if isCheck(player, snapshot: snapshot) {
            isCheckMate = true
            for piece in player.pieces where isCheckMate == true {
                for index in board.indexes {
                    let position = board.position(index)
                    let translation = calculateTranslation(piece.position, toPosition: position, direction: player.forwardDirection)
                    if piece.isPossibleTranslation(translation) {   // eliminate some iterations
                        self.reusableGameSnapshot = GameSnapshot(game: self)//not using snapshot para
                        let moveFunction = piece.isLegalMove(translation)
                        let pieceConditions = pieceConditionsAreMet(piece, conditions: moveFunction.conditions, snapshot: self.reusableGameSnapshot)
                        
                        if moveFunction.isLegal && pieceConditions.isMet {
                            
                            // remove occupying piece if needed
                            let occupyingPiece = pieceForPosition(position, snapshot: self.reusableGameSnapshot)
                            if piece.removePieceOccupyingNewPosition == true && occupyingPiece != nil {
                                makeMoveInSnapshot(Move(piece: occupyingPiece!, remove: true, position: nil), snapshot: self.reusableGameSnapshot!)
                            }
                            
                            // move the piece
                            makeMoveInSnapshot(Move(piece: piece, remove: false, position: position), snapshot: self.reusableGameSnapshot!)
                            
                            // completions
                            if let completions = pieceConditions.completions {
                                for completion in completions {
                                    completion()
                                }
                            }
                        
                            if isCheck(player, snapshot: self.reusableGameSnapshot) == false {
                                isCheckMate = false
                            }
                        }
                    }
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













