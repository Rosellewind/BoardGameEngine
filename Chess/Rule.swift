//
//  Rule.swift
//  Chess
//
//  Created by Roselle Tanner on 12/5/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

struct IsMetAndCompletions {
    let isMet: Bool
    let completions: [(() -> Void)]?
}

protocol Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions
}



// MARK: Basic Conditions

class MustBeVacantCell: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            if !snapshot.board.isACellAndIsNotEmpty(index: snapshot.board.index(position: positionToCheck)) {
                isMet = false
            } else {
                let pieceOccupying = snapshot.pieceForPosition(positionToCheck, snapshot: snapshot)
                if pieceOccupying != nil {
                    isMet = false
                }
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class MustBeOccupied: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let pieceOccupying = snapshot.pieceForPosition(positionToCheck, snapshot: snapshot)
            if pieceOccupying == nil {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class MustBeOccupiedByOpponent: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let pieceOccupying = snapshot.pieceForPosition(positionToCheck, snapshot: snapshot)
            if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class CantBeOccupiedBySelf: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let pieceOccupying = snapshot.pieceForPosition(positionToCheck, snapshot: snapshot)
            if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class IsInitialMove: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        if !piece.isFirstMove {
            isMet = false
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}


// MARK: Chess Conditions

class CantBeInCheck: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }

        // all other players pieces can not take king
        var isCheck = false
        let thisPlayer = snapshot.players.elementPassing({$0.id == player.id}) ?? player
        let allPlayers = snapshot.players
        
        if let king = thisPlayer.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in allPlayers where isCheck == false {
                if otherPlayer === thisPlayer {
                    continue
                } else {
                    for otherPlayerPiece in otherPlayer.pieces where isCheck == false {
                        let translationToCaptureKing = Position.calculateTranslation(fromPosition: otherPlayerPiece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = otherPlayerPiece.isLegalMove(translationToCaptureKing)// bool, conditions
                        if moveFunction.isLegal {
                            // if its a legal move, check the conditions
                            let hasConditions = moveFunction.legalIf != nil || moveFunction.legalIf!.count != 0
                            if !hasConditions {
                                isCheck = true
                            }
                            for conditionTuple in moveFunction.legalIf! where isCheck == false {
                                let x = conditionTuple.condition.checkIfConditionIsMet(piece: otherPlayerPiece, translations: conditionTuple.translations!, snapshot: snapshot)
                                if x.isMet == true {
                                    isCheck = true
                                }
                            }
                        }
                    }
                }
            }
        }
        return IsMetAndCompletions(isMet: !isCheck, completions: nil)
    }
}

class CantLandInCheck: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        var completions: [(() -> Void)]? = nil
        guard let player = piece.player, let translations = translations else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        let translation = translations[translations.count - 1]
        let cantBeInCheckDuring = CantBeInCheckDuring()
        let conditionStatus = cantBeInCheckDuring.checkIfConditionIsMet(piece: piece, translations: [translation], snapshot: snapshot)
        if conditionStatus.isMet == false {
            isMet = false
//            completions =
//            if self.presenterDelegate != nil {
//                completions = [{self.presenterDelegate!.secondaryGameMessage(string: "You can't leave yourself in check")}]
//            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }
}

class CantBeInCheckDuring: Condition {//////////doesen't remove piece in snapshot
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player, let translations = translations  else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations {
            
            // move in snapshot, check if in check
            let secondSnapshot = GameSnapshot(gameSnapshot: snapshot)
            let position = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            secondSnapshot.makeMove(Move(piece: piece, remove: piece.removePieceOccupyingNewPosition, position: position))
            if isCheck(player: player, snapshot: secondSnapshot) {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
    
    func isCheck(player: Player, snapshot: GameSnapshot) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        let thisPlayer = snapshot.players.elementPassing({$0.id == player.id}) ?? player
        let allPlayers = snapshot.players
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
                                let x = conditionTuple.condition.checkIfConditionIsMet(piece: otherPlayerPiece, translations: conditionTuple.translations!, snapshot: snapshot)
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
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
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
                let rookOnRight = rook.position.column - king.position.column > 0
                var columns: CountableRange<Int> = 0..<1
                if kingMovingToTheRight {
                    landingPositionForRook = Position(row: king.position.row, column: king.position.column - 1)
                    if rookOnRight {
                        columns = kingLandingPosition.column+1..<rook.position.column
                    } else {
                        columns = rook.position.column+1..<king.position.column
                    }
                } else {
                    landingPositionForRook = Position(row: king.position.row, column: king.position.column + 1)
                    if rookOnRight {
                        columns = king.position.column+1..<rook.position.column
                    } else {
                        columns = rook.position.column+1..<kingLandingPosition.column
                    }
                }
                
                let rookLandingTranslation = Position.calculateTranslation(fromPosition: rook.position, toPosition: landingPositionForRook, direction: player.forwardDirection)
                let moveFunction = rook.isLegalMove(rookLandingTranslation)
                if moveFunction.isLegal {
                    // check conditions, just need to be vacant between rook and king
                    var translationsMustBeVacant = [Translation]()
                    for column in columns {
                        translationsMustBeVacant.append(Translation(row: rook.position.row, column: column))
                    }
                    let x = MustBeVacantCell().checkIfConditionIsMet(piece: rook, translations: translationsMustBeVacant, snapshot: snapshot)
                    if x.isMet == true {
                        castlingRooks.append(rook)
                    }
                }
            }
        }
        
        if castlingRooks.count == 0 {
            isMet = false
        } else {
            // move the rook
            isMet = true
            completions = [{self.moveARook(castlingRooks: castlingRooks, position: landingPositionForRook)}]
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions)
    }

    func moveARook(castlingRooks rooks: [Piece], position: Position) {
//        if rooks.count == 2 {
//            
//            // find the direction the player is moving
//            var playerOrientation = ChessPlayerOrientation.bottom
//            if let player = rooks[0].player as? ChessPlayer {
//                playerOrientation = player.orientation
//            }
//            
//            // have the presenting VC ask which rook to use
//            let alert = UIAlertController(title: "Castling", message: "Which rook do you want to use?", preferredStyle: .alert)
//            let leftAction = UIAlertAction(title: "Left", style: .default, handler: { (action: UIAlertAction) in
//                let leftRook: Piece
//                switch playerOrientation {
//                case .bottom:
//                    leftRook = rooks[0].position.column < rooks[1].position.column ? rooks[0] : rooks[1]
//                case .top:
//                    leftRook = rooks[0].position.column > rooks[1].position.column ? rooks[0] : rooks[1]
//                case .left:
//                    leftRook = rooks[0].position.row < rooks[1].position.row ? rooks[0] : rooks[1]
//                case .right:
//                    leftRook = rooks[0].position.row > rooks[1].position.row ? rooks[0] : rooks[1]
//                }
//                self.makeMove(Move(piece: leftRook, remove: false, position: position))
//                alert.dismiss(animated: true, completion: nil)
//            })
//            alert.addAction(leftAction)
//            let rightAction = UIAlertAction(title: "Right", style: .default, handler: { (action: UIAlertAction) in
//                let rightRook: Piece
//                switch playerOrientation {
//                case .bottom:
//                    rightRook = rooks[0].position.column > rooks[1].position.column ? rooks[0] : rooks[1]
//                case .top:
//                    rightRook = rooks[0].position.column < rooks[1].position.column ? rooks[0] : rooks[1]
//                case .left:
//                    rightRook = rooks[0].position.row > rooks[1].position.row ? rooks[0] : rooks[1]
//                case .right:
//                    rightRook = rooks[0].position.row < rooks[1].position.row ? rooks[0] : rooks[1]
//                }
//                self.makeMove(Move(piece: rightRook, remove: false, position: position))
//                alert.dismiss(animated: true, completion: nil)
//            })
//            alert.addAction(rightAction)
//            presenterDelegate?.showAlert(alert)
//        } else if rooks.count == 1 {
//            self.makeMove(Move(piece: rooks[0], remove: false, position: position))
//        }
    }
}

class CheckForPromotion: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        return IsMetAndCompletions(isMet: false, completions: nil)
    }

    
}

class MarkAdvancedTwo: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        let completion: () -> Void = {(piece as? PawnPiece)?.roundWhenPawnAdvancedTwo = snapshot.round}
        return IsMetAndCompletions(isMet: true, completions: [completion])

    }
}

class MustBeOccupiedByOpponentOrEnPassant: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, snapshot: GameSnapshot) -> IsMetAndCompletions {
        var isMet = false
        guard let player = piece.player, let translations = translations else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
//        for translation in translations ?? [] {
//
//            }
//        }
        
    
    
    
        if translations.count == 2 {
            let landingTranslation = translations[0]
            
            
            
            
            var enPassantPawn: PawnPiece? = nil
            let enPassantPosition = Position.positionFromTranslation(translations[1], fromPosition: piece.position, direction: player.forwardDirection)
            if let possiblePawn = snapshot.pieceForPosition(enPassantPosition, snapshot: nil) as? PawnPiece {
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
            
            
            if enPassantPawn != nil {
                let enPassantCompletion: () -> Void = {self.removePieceAndViewFromGame(piece: enPassantPawn!)}
                completions!.append(enPassantCompletion)
                isMet = true
            } else {
                isMet = occupiedCondition.isMet
                if occupiedCondition.completions != nil{////del
                    completions! += occupiedCondition.completions!
                }                                }
        }
        return IsMetAndCompletions(isMet: false, completions: nil)

    }
    
    func playerIndex(player: Player) -> Int? {
        return players.index(where: {$0.id == player.id})
    }
}

/*
    override func pieceConditionsAreMet(_ piece: Piece, conditions: [(condition: Int, translations: [Translation]?)]?, snapshot: GameSnapshot?) -> (isMet: Bool, completions: [(() -> Void)]?) {
        let pieceInSnapshot = snapshot?.allPieces.elementPassing({$0.id == piece.id})
        let thisPiece = pieceInSnapshot ?? piece
        var isMet = true
        var completions: [()->Void]? = Array<()->Void>()
        
        guard let player = thisPiece.player, thisPiece.player != nil else {
            return (false, nil)
        }
        
        for condition in conditions ?? [] where isMet == true {
            if LegalIfCondition(rawValue: condition.condition) != nil {
                let superConditionsAreMet = super.pieceConditionsAreMet(piece, conditions: [condition], snapshot: snapshot)
                isMet = superConditionsAreMet.isMet
                completions = superConditionsAreMet.completions ?? Array<()->Void>()
            }
            else if let chessLegalIfCondition = ChessLegalIfCondition(rawValue:condition.condition) {
                switch chessLegalIfCondition {
                case .rookCanCastle:
                    // king moves 2 horizontally, rook goes where king just crossed
                    // 1. neither the king nor the rook may have been previously moved
                    // 2. there must not be pieces between the king and rook
                    // 3. the king may not be in check, nor may the king pass through squares athat are under attack by eney pieces, nor move to a square where it is in check
                    
                    // this func: rook hasn't moved yet, no pieces from next to landing to rook
                    
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
                        completions = []
                    } else {
                        // move the rook
                        
                        
                        let completion: () -> Void = { self.moveARook(castlingRooks, position: landingPositionForRook)}
                        completions!.append(completion)
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
                                completions = []
                                if self.presenterDelegate != nil {
                                    completions = [{self.presenterDelegate!.secondaryGameMessage(string: "You can't leave yourself in check")}]
                                }
                            }
                        }
                    }
                case .markAdvancedTwo:
                    let completion: () -> Void = {(piece as? PawnPiece)?.roundWhenPawnAdvancedTwo = self.round}
                    completions!.append(completion)
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
                            
                            
                            if enPassantPawn != nil {
                                let enPassantCompletion: () -> Void = {self.removePieceAndViewFromGame(piece: enPassantPawn!)}
                                completions!.append(enPassantCompletion)
                                isMet = true
                            } else {
                                isMet = occupiedCondition.isMet
                                if occupiedCondition.completions != nil{
                                    completions! += occupiedCondition.completions!
                                }                                }
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
                    completions!.append(checkPromotionCompletion)
                    isMet = true
                }
            }
        }
        
        if completions!.count == 0 {            return (isMet, nil)
        } else {
            return (isMet, completions)
        }
}
*/
