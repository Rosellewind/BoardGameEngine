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
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions
}



// MARK: Basic Conditions

class MustBeVacantCell: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] where isMet == true {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            if !game.board.isACellAndIsNotEmpty(index: game.board.index(position: positionToCheck)) {
                isMet = false
            } else {
                let pieceOccupying = game.piece(position: positionToCheck)
                if pieceOccupying != nil {
                    isMet = false
                }
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class MustBeOccupied: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] where isMet == true {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let pieceOccupying = game.piece(position: positionToCheck)
            if pieceOccupying == nil {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class MustBeOccupiedByOpponent: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] where isMet == true {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let pieceOccupying = game.piece(position: positionToCheck)
            if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class CantBeOccupiedBySelf: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = true
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        for translation in translations ?? [] where isMet == true {
            let positionToCheck = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let pieceOccupying = game.piece(position: positionToCheck)
            if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                isMet = false
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class IsInitialMove: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = true
        if !piece.isFirstMove {
            isMet = false
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

