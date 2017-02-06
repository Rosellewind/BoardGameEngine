//
//  GalaxyRules.swift
//  Chess
//
//  Created by Roselle Tanner on 1/18/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import Foundation

class DeleteEdgeCellsTouchingAllEmpty: Condition {          // put translation in vacantCellsCount, haven't moved yet
    static var shared: Condition = DeleteEdgeCellsTouchingAllEmpty()
    private init() {}
    func checkIfConditionIsMet(piece: Piece, translations: [Translation]?, game: Game) -> IsMetAndCompletions {
        var completions =  [Completion]()
        for edge in game.board.nonSkippedEdges() {
            let borderingCells = game.board.boarderedCells(position: edge)
            var vacantCellsCount = 0
            borderingCells.forEach({ (position: Position) in
                if game.piece(position: position) == nil {
                    vacantCellsCount += 1
                }
            })
            let isVacantAdjoiningCells = borderingCells.count == vacantCellsCount
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
