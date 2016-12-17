////
////  x.swift
////  Chess
////
////  Created by Roselle Tanner on 12/16/16.
////  Copyright © 2016 Roselle Tanner. All rights reserved.
////
//
//import Foundation
//
//// king moves 2 horizontally, rook goes where king just crossed
//// 1. neither the king nor the rook may have been previously moved
//// 2. there must not be pieces between the king and rook
//// 3. the king may not be in check, nor may the king pass through squares athat are under attack by eney pieces, nor move to a square where it is in check
//
//let rooks = player.pieces.filter({$0.name.hasPrefix("Rook")})
//var castlingRooks = [Piece]()
//var landingPositionForRook = Position(row: 0, column: 0)
//if let king = player.pieces.elementPassing({$0.name == "King"}) {
//    for rook in rooks {
//        
//        // checks half of rule 1, rook can't be previously moved
//        if rook.isFirstMove {
//            
//            if let rookLandingTranslationRelativeToKing = condition.translations?[0] {
//                
//                // checks half of rule 2, can't be pieces between rook and where rook is landing OR between the rook and king if rook crosses past kings initial position
//                var translation: Translation
//                landingPositionForRook = positionFromTranslation(rookLandingTranslationRelativeToKing, fromPosition: king.position, direction: player.forwardDirection)
//                
//                let startingSide = king.position.column - rook.position.column < 0 ? -1 : 1
//                let endingSide = king.position.column - landingPositionForRook.column < 0 ? -1 : 1
//                let rookCrossesKing = startingSide != endingSide
//                if rookCrossesKing {
//                    let positionOneBackFromKing = Position(row: king.position.row, column: king.position.column + endingSide)
//                    translation = calculateTranslation(rook.position, toPosition: positionOneBackFromKing, direction: player.forwardDirection)
//                } else {
//                    translation = calculateTranslation(rook.position, toPosition: landingPositionForRook, direction: player.forwardDirection)
//                    
//                }
//                let moveFunction = rook.isLegalMove(translation)
//                if pieceConditionsAreMet(rook, conditions: moveFunction.conditions, snapshot: snapshot).isMet {
//                    castlingRooks.append(rook)
//                }
//            }
//        }
//    }
//}
//if castlingRooks.count == 0 {
//    isMet = false
//    completions = []
//} else {
//    // move the rook
//    
//    
//    let completion: () -> Void = { self.moveARook(castlingRooks, position: landingPositionForRook)}
//    completions!.append(completion)
//    isMet = true
//}
