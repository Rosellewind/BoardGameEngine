//
//  GalaxyRules.swift
//  Chess
//
//  Created by Roselle Tanner on 1/18/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import Foundation

struct DeleteEdgeCellsTouchingAllEmpty: Condition {
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var completions =  [Completion]()
        for edge in game.board.nonSkippedEdges() {
            var borderingCells = game.board.boarderedCells(position: edge)
            borderingCells.append(edge)
            var vacantCellsCount = 0
            borderingCells.forEach({ (position: Position) in
                let pieceWithinBorder = game.piece(position: position)
                if pieceWithinBorder == nil || pieceWithinBorder! == piece {
                    vacantCellsCount += 1
                }
            })
            
            var isVacantAdjoiningCells = borderingCells.count == vacantCellsCount

            // account for piece landing
            if isVacantAdjoiningCells, let translation = translations?[0] {
                let landingPosition = Position.positionFromTranslation(translation, fromPosition: piece.position, direction: piece.player?.forwardDirection ?? Direction.left)  ////?
                if borderingCells.contains(landingPosition) {
                    isVacantAdjoiningCells = false
                }
            }
            
            if isVacantAdjoiningCells {
                if game.vc != nil {
                    completions.append(Completion(closure: {game.vc!.removeCellAndViewFromGame(position: edge)}, evenIfNotMet: false))
                } else {
                    completions.append(Completion(closure: {game.removeCell(position: edge)}, evenIfNotMet: false))
                }
            }
        }
        return IsMetAndCompletions(isMet: true, completions: completions.count > 0 ? completions : nil)
    }
}
