//
//  Chess Rules.swift
//  Chess
//
//  Created by Roselle Tanner on 12/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


// MARK: Chess Conditions

class CantBeInCheck: Condition {
    static var shared: Condition = CantBeInCheck()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        print("...")
        var isMet = true
        var completions: [Completion]? = nil
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
                completions = [Completion(closure: {game.vc?.presenterDelegate?.secondaryGameMessage(string: "Can't leave yourself in check")}, evenIfNotMet: true)]
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }
    
    func isCheck(player: Player, game: Game) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        guard let player = game.players.elementPassing({$0.id == player.id}) else {
            return false
        }
        
        if let king = player.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in game.players where isCheck == false {
                if otherPlayer === player {
                    continue
                } else {
                    for otherPlayerPiece in otherPlayer.pieces where isCheck == false {
                        let translationToCaptureKing = Position.calculateTranslation(fromPosition: otherPlayerPiece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = otherPlayerPiece.isLegalMove(translationToCaptureKing)
                        if moveFunction.isLegal {
                            // give chance for condition to make isCheck false
                            let isMetAndCompletions = game.checkIfConditionsAreMet(piece: otherPlayerPiece, legalIfs: moveFunction.legalIf)
                            if isMetAndCompletions.isMet {
                                isCheck = true
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
    static var shared: Condition = RookCanCastle()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        // king moves 2 horizontally, rook goes where king just crossed
        // 1. neither the king nor the rook may have been previously moved
        // 2. there must not be pieces between the king and rook
        // 3. the king may not be in check, nor may the king pass through squares athat are under attack by eney pieces, nor move to a square where it is in check
        
        
        // this func checks: rook hasn't moved yet, no pieces from next to landing to rook
        var isMet: Bool
        var completions: [Completion]? = nil
        guard let player = piece.player, let king = player.pieces.elementPassing({$0.name == "King"}), let kingTranslation = translations?[0]  else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        let rooks = player.pieces.filter({$0.name.hasPrefix("Rook")})
        let kingLandingPosition = Position.positionFromTranslation(kingTranslation, fromPosition: king.position, direction: player.forwardDirection)
        let kingDirection = kingTranslation.column > 0 ? 1 : -1
        let rookLandingPosition = Position.positionFromTranslation(Translation(row: kingTranslation.row, column: kingTranslation.column - kingDirection), fromPosition: king.position, direction: player.forwardDirection)
        var castlingRook: Piece? = nil
        for rook in rooks {
            let rookTranslation = Position.calculateTranslation(fromPosition: rook.position, toPosition: rookLandingPosition, direction: player.forwardDirection)
            let rookDirection = rookTranslation.column > 0 ? 1 : -1
            if kingDirection != rookDirection {
                // checks half of rule 1, rook can't be previously moved
                if rook.isFirstMove{
                    // check half of rule 2, if no pieces between rook and kingLanding
                    let mustBeEmptyPositions = Position.betweenLinearExclusive(position1: kingLandingPosition, position2: rook.position)
                    let mustBeEmptyTranslations = mustBeEmptyPositions.map({ (position: Position) -> Translation in
                        Position.calculateTranslation(fromPosition: rook.position, toPosition: position, direction: player.forwardDirection)
                    })
                    let conditionsMet = MustBeVacantCell.shared.checkIfConditionIsMet(piece: rook, translations: mustBeEmptyTranslations, game: game)
                    if conditionsMet.isMet == true {
                        castlingRook = rook
                        break
                    }
                }
            }
            
        }
        if castlingRook != nil {
            // move the rook
            isMet = true
            completions = [Completion(closure: {game.movePiece(piece: castlingRook!, position: rookLandingPosition, removeOccupying: false)}, evenIfNotMet: false)]
        } else {
            isMet = false
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }
}

class CheckForPromotion: Condition {
    static var shared: Condition = CheckForPromotion()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        guard let vc = game.vc else {
            return IsMetAndCompletions(isMet: true, completions: nil)
        }
        let checkPromotionClosure: () -> Void = {
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
        
        return IsMetAndCompletions(isMet: true, completions: [Completion(closure: checkPromotionClosure
            , evenIfNotMet: false)])
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
    static var shared: Condition = MarkAdvancedTwo()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        let closure: () -> Void = {(piece as? PawnPiece)?.roundWhenPawnAdvancedTwo = game.round}
        return IsMetAndCompletions(isMet: true, completions: [Completion(closure: closure, evenIfNotMet: false)])
    }
}

class MustBeOccupiedByOpponentOrEnPassant: Condition {
    static var shared: Condition = MustBeOccupiedByOpponentOrEnPassant()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = false
        var completions: [Completion]? = nil
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
                    completions = [Completion(closure: {game.vc!.removePieceAndViewFromGame(piece: enPassantPawn!)}, evenIfNotMet: false)]
                } else {
                    completions = [Completion(closure: {game.removePiece(piece: enPassantPawn!)}, evenIfNotMet: false)]
                }
                isMet = true
            } else {                    // is pawn attack move
                return MustBeOccupied.shared.checkIfConditionIsMet(piece: piece, translations: [landingTranslation], game: game)                               }
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }
}
