//
//  Rule.swift
//  Chess
//
//  Created by Roselle Tanner on 12/5/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

struct Completion {
    let closure: (() -> Void)
    let evenIfNotMet: Bool
}

struct IsMetAndCompletions {
    let isMet: Bool
    let completions: [Completion]?
}

protocol Condition {
    static var shared: Condition {get}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions
}


// MARK: Basic Conditions

class MustBeVacantCell: Condition {
    static var shared: Condition = MustBeVacantCell()
    private init() {}
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
    static var shared: Condition = MustBeOccupied()
    private init() {}
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
    static var shared: Condition = MustBeOccupiedByOpponent()
    private init() {}
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
    static var shared: Condition = CantBeOccupiedBySelf()
    private init() {}
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
    static var shared: Condition = IsInitialMove()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var isMet = true
        if !piece.isFirstMove {
            isMet = false
        }
        return IsMetAndCompletions(isMet: isMet, completions: nil)
    }
}

class RemoveOpponent: Condition {
    static var shared: Condition = RemoveOpponent()
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        guard let player = piece.player else {
            return IsMetAndCompletions(isMet: false, completions: nil)
        }
        var completions =  [Completion]()
        for translation in translations ?? [] {
            let positionToRemove = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
            let piecesToRemove = game.pieces(position: positionToRemove)?.filter({$0.player != nil && $0.player! != player})
            
            for pieceToRemove in piecesToRemove ?? [] {
                completions.append(Completion(closure: {game.removePiece(piece: pieceToRemove)}, evenIfNotMet: false))
            }
        }
        return IsMetAndCompletions(isMet: true, completions: completions.count > 0 ? completions : nil)
    }
}

