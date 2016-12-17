//
//  Chess Rules.swift
//  Chess
//
//  Created by Roselle Tanner on 12/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class CantBeInCheck: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        print("...")
        var isMet = true
        guard let player = piece.player, let translations = translations  else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations {
            
            // move in game, check if in check
            let gameCopy = game.copy()
            let position = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            gameCopy.movePieceMatching(piece: piece, position: position, removeOccupying: piece.removePieceOccupyingNewPosition)
            
            if isCheck(player: player, game: gameCopy) {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
    
    func isCheck(player: Player, game: Game) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        let thisPlayer = game.players.elementPassing({$0.id == player.id}) ?? player
        let allPlayers = game.players
        if let king = thisPlayer.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in allPlayers where isCheck == false {
                if otherPlayer === thisPlayer {
                    continue
                } else {
                    for otherPlayerPiece in otherPlayer.pieces where isCheck == false {////false checked at top
                        let translationToCaptureKing = Position.calculateTranslation(fromPosition: otherPlayerPiece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = otherPlayerPiece.isLegalMove(translationToCaptureKing)// -> bool, conditions
                        if moveFunction.isLegal {
                            // give chance for condition to make isCheck false
                            isCheck = true
                            for conditionTuple in moveFunction.legalIf! where isCheck == true {
                                let x = conditionTuple.condition.checkIfConditionIsMet(piece: otherPlayerPiece, translations: conditionTuple.translations!, game: game)
                                if x.isMet == false {
                                    isCheck = false
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        return isCheck
    }
}

class RookCanCastle: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        // king moves 2 horizontally, rook goes where king just crossed
        // 1. neither the king nor the rook may have been previously moved
        // 2. there must not be pieces between the king and rook
        // 3. the king may not be in check, nor may the king pass through squares athat are under attack by eney pieces, nor move to a square where it is in check
        
        
        // this func: rook hasn't moved yet, no pieces from next to landing to rook
        var isMet: Bool
        var completions: [(() -> Void)]? = nil
        guard let player = piece.player, let king = player.pieces.elementPassing({$0.name == "King"}), let translations = translations  else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        
        let rooks = player.pieces.filter({$0.name.hasPrefix("Rook")})
        var castlingRooks = [Piece]()
        var landingPositionForRook = Position(row: 0, column: 0)
        for rook in rooks {
            
            // checks half of rule 1, rook can't be previously moved
            if rook.isFirstMove && translations.count > 0 {
                
                // check if no pieces between
                // translation is +2 or -2
                let kingTranslation = translations[0]
                let kingLandingPosition = Position.positionFromTranslation(kingTranslation, fromPosition: king.position, direction: player.forwardDirection)
                let kingMovingToTheRight = kingTranslation.column > 0
                let rookIsOnRight = rook.position.column - king.position.column > 0
                var columnsThatMustBeEmpty: CountableRange<Int> = 0..<1
                if kingMovingToTheRight {
                    landingPositionForRook = Position(row: kingLandingPosition.row, column: kingLandingPosition.column - 1)
                    if rookIsOnRight {
                        columnsThatMustBeEmpty = kingLandingPosition.column+1..<rook.position.column
                    } else {
                        columnsThatMustBeEmpty = rook.position.column+1..<king.position.column
                    }
                } else {    // king is moving to the left
                    landingPositionForRook = Position(row: kingLandingPosition.row, column: kingLandingPosition.column + 1)
                    if rookIsOnRight {
                        columnsThatMustBeEmpty = king.position.column+1..<rook.position.column
                    } else {
                        columnsThatMustBeEmpty = rook.position.column+1..<kingLandingPosition.column
                    }
                }
                
                let rookLandingTranslation = Position.calculateTranslation(fromPosition: rook.position, toPosition: landingPositionForRook, direction: player.forwardDirection)
                
                var translationsMustBeVacant = [Translation]()
                for column in columnsThatMustBeEmpty {
                    let translationThatMustVacant = Position.calculateTranslation(fromPosition: rook.position, toPosition: Translation(row: rook.position.row, column: column), direction: player.forwardDirection)
                    translationsMustBeVacant.append(translationThatMustVacant)
                }
                let x = MustBeVacantCell().checkIfConditionIsMet(piece: rook, translations: translationsMustBeVacant, game: game)
                if x.isMet == true {
                    castlingRooks.append(rook)
                }
            }
        }
        
        if castlingRooks.count == 0 {
            isMet = false
        } else {
            // move the rook
            isMet = true
            completions = [{self.moveARook(castlingRooks: castlingRooks, position: landingPositionForRook, game: game)}]
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }
    
    func moveARook(castlingRooks rooks: [Piece], position: Position, game: Game) {
        if rooks.count == 2 {
            guard let vc = game.vc else {
                return
            }
            
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
                game.movePiece(piece: leftRook, position: position, removeOccupying: false)
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
                game.movePiece(piece: rightRook, position: position, removeOccupying: false)
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(rightAction)
            vc.presenterDelegate?.showAlert(alert)
        } else if rooks.count == 1 {
            game.movePiece(piece: rooks[0], position: position, removeOccupying: false)
        }
    }
}

class CheckForPromotion: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        guard let vc = game.vc else {
            return IsMetAndCompletions(isMet: true, completions: nil)
        }
        let checkPromotionCompletion: () -> Void = {
            if let direction = piece.player?.forwardDirection {
                var hasReachedEighthRank = false
                switch direction {
                case .bottom:
                    hasReachedEighthRank = piece.position.row == game.board.numRows - 1
                case .left:
                    hasReachedEighthRank = piece.position.column == 0
                case .right:
                    hasReachedEighthRank = piece.position.column == game.board.numColumns - 1
                case .top:
                    hasReachedEighthRank = piece.position.row == 0
                }
                if hasReachedEighthRank {
                    // have the presenting VC ask what promotion they want
                    let alert = UIAlertController(title: "Promotion", message: "Which chess piece do you want to promote your pawn with?", preferredStyle: .actionSheet)
                    let queen = UIAlertAction(title: "Queen", style: .default, handler: {(UIAction) in
                        self.promote(piece: piece, toType: .Queen, game: game)
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(queen)
                    let knight = UIAlertAction(title: "Knight", style: .default, handler: {(UIAction) in
                        self.promote(piece: piece, toType: .Knight, game: game)
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(knight)
                    let rook = UIAlertAction(title: "Rook", style: .default, handler: {(UIAction) in
                        self.promote(piece: piece, toType: .Rook, game: game)
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(rook)
                    let bishop = UIAlertAction(title: "Bishop", style: .default, handler: {(UIAction) in
                        self.promote(piece: piece, toType: .Bishop, game: game)
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(bishop)
                    vc.presenterDelegate?.showAlert(alert)
                }
            }
        }
        return IsMetAndCompletions(isMet: true, completions: [checkPromotionCompletion])
    }
    
    fileprivate func promote(piece: Piece, toType: ChessPieceType, game: Game) {
        
        // create replacement
        let newPiece = ChessPieceCreator.shared.chessPiece(toType)
        newPiece.position = piece.position
        newPiece.id = piece.id
        newPiece.isFirstMove = piece.isFirstMove
        newPiece.startingPosition = piece.startingPosition
        newPiece.player = piece.player
        newPiece.selected = piece.selected
        
        // replace it
        if game.vc != nil {
            game.vc!.replacePieceAndView(piece: piece, withPiece: newPiece)
        } else {
            game.replacePiece(piece: piece, withPiece: newPiece)
        }
    }
}

class MarkAdvancedTwo: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        let completion: () -> Void = {(piece as? PawnPiece)?.roundWhenPawnAdvancedTwo = game.round}
        return IsMetAndCompletions(isMet: true, completions: [completion])
        
    }
}

class MustBeOccupiedByOpponentOrEnPassant: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = false
        var completions: [(() -> Void)]? = nil
        guard let player = piece.player, let translations = translations else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        
        if translations.count == 2 {
            let landingTranslation = translations[0]        // the first translation is where it will land
            var enPassantPawn: PawnPiece? = nil
            let enPassantPosition = Position.positionFromTranslation(translations[1], fromPosition: piece.position, direction: player.forwardDirection) // the second translation is en passant position
            if let possiblePawn = game.piece(position: enPassantPosition) as? PawnPiece, let roundWhenPawnAdvancedTwo = possiblePawn.roundWhenPawnAdvancedTwo, let pawnPlayerIndex = game.playerIndex(player: player), let enPassantPlayer = possiblePawn.player, let enPassantPlayerIndex = game.playerIndex(player: enPassantPlayer)  {
                if pawnPlayerIndex != enPassantPlayerIndex {
                    let isBetween = pawnPlayerIndex.isBetweenInForwardLoop(firstInclusive: game.firstInRound, lastNotInclusive: enPassantPlayerIndex)
                    let isStillFirstRoundSinceAdvancedTwo = (isBetween && game.round == roundWhenPawnAdvancedTwo + 1) || (!isBetween && game.round == roundWhenPawnAdvancedTwo)
                    if isStillFirstRoundSinceAdvancedTwo {
                        enPassantPawn = possiblePawn
                    }
                }
            }
            
            if enPassantPawn != nil {   // is en passant move
                
                if game.vc != nil {
                    completions = [{game.vc!.removePieceAndViewFromGame(piece: enPassantPawn!)}]
                } else {
                    completions = [{game.removePiece(piece: enPassantPawn!)}]
                }
                isMet = true
            } else {                    // is pawn attack move
                return MustBeOccupied().checkIfConditionIsMet(piece: piece, translations: [landingTranslation], game: game)                               }
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }
}
