//
//  Game.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

// TODO:


import UIKit


protocol GamePresenterProtocol: class {
    func gameMessage(_ string: String, status: GameStatus?)
    func secondaryGameMessage(string: String)
    func showAlert(_ alert: UIViewController)
}

enum GameStatus {
    case gameOver, whoseTurn, illegalMove, `default`
}

typealias Completions = [(() -> Void)]

class Game {
    var board: Board
    var players: [Player]
    var selectedPiece: Piece?
    var round = 0
    var firstInRound = 0
    var whoseTurn: Int = 0 {
        didSet {
            if whoseTurn >= players.count {
                whoseTurn = 0
                round += 1
            }
        }
    }
    var nextTurn: Int {
        get {
            var next = whoseTurn + 1
            if next >= players.count {
                next = 0
            }
            return next
        }
    }
    var allPieces: [Piece] {
        get {
            var pieces = [Piece]()
            for player in players {
                pieces += player.pieces
            }
            return pieces
        }
    }
    weak var vc: GameVC?
    
    init(board: Board, players: [Player]) {
        self.board = board
        self.players = players
    }

    func copy() -> Game {
        let game = Game(board: board.copy(), players: players.map({$0.copy()}))
        game.selectedPiece = allPieces.elementPassing({$0.id == selectedPiece?.id})
        game.round = round
        game.firstInRound = firstInRound
        game.whoseTurn = whoseTurn
//        game.vc = vc
        return game
    }
    
    func pieces(position: Position) -> [Piece]? {
        var pieces = [Piece]()
        for piece in allPieces {
            if piece.position == position {
                pieces.append(piece)
            }
        }
        return pieces.count > 0 ? pieces : nil
    }
    
    func piece(position: Position) -> Piece? {
        for piece in allPieces {
            if piece.position == position {return piece}
        }
        return nil
    }
    
    func piece(tag: Int) -> Piece? {
        for piece in allPieces {
            if piece.id == tag {return piece}
        }
        return nil
    }
    
    func addPiece(piece: Piece) {
        if let player = piece.player {
            player.pieces.append(piece)
        }
    }
    
    func removePiece(piece: Piece) {
        if let index = piece.player?.pieces.index(of: piece) {
            piece.player!.pieces.remove(at: index)
        }
    }
    
    func removePieceMatching(piece: Piece) {
        guard let matchingPiece = self.allPieces.elementPassing({$0.id == piece.id && $0.player != nil && $0.player!.id == piece.player!.id}) else {
            return
        }
        removePiece(piece: matchingPiece)
    }

    func movePiece(piece: Piece, position: Position, removeOccupying: Bool) {
        if removeOccupying, let piecesToRemove = self.pieces(position: position) {
            for pieceToRemove in piecesToRemove {
                removePiece(piece: pieceToRemove)
            }
        }
        piece.position = position
    }
    
    func movePieceMatching(piece: Piece, position: Position, removeOccupying: Bool) {
        guard let matchingPiece = self.allPieces.elementPassing({$0.id == piece.id && $0.player != nil && $0.player!.id == piece.player!.id}) else {
            return
        }
        movePiece(piece: matchingPiece, position: position, removeOccupying: removeOccupying)
    }
    
    func replacePiece(piece piece1: Piece, withPiece piece2: Piece) {
        removePiece(piece: piece1)
        addPiece(piece: piece2)
    }
    
    func playerIndex(player: Player) -> Int? {
        return players.index(where: {$0.id == player.id})
    }
    
    func checkIfConditionsAreMet(piece: Piece,  legalIfs: [LegalIf]?) -> IsMetAndCompletions {
        if legalIfs == nil {
            return IsMetAndCompletions(isMet: true, completions: nil)
        }
        var isMet = true
        var completions: [(() -> Void)]? =  [(() -> Void)]()
        for legalIf in legalIfs! where isMet == true {
            let isMetAndCompletions = legalIf.condition.checkIfConditionIsMet(piece: piece, translations: legalIf.translations, game: self)
            
            isMet = isMetAndCompletions.isMet
            if let complete = isMetAndCompletions.completions {
                completions! += complete
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions!.count > 0 ? completions : nil)
    }
    
    func printPieces() {
        for player in players {
            for piece in player.pieces {
                print("\(player.name) \(piece.name) \(piece.position.row) \(piece.position.column)")

            }
        }
    }
}




