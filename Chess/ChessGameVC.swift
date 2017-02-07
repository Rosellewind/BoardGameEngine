//
//  AllChess.swift
//  ChessGameVC
//
//  Created by Roselle Milvich on 6/13/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


enum ChessVariation: Int, GameVariation {
    case standardChess, fourPlayer, fourPlayerX
    static let allValues = [standardChess, fourPlayer, fourPlayerX]
    func screenName() -> String {
        switch self {
        case .standardChess:
            return "Chess"
        case .fourPlayer:
            return "Four Player Chess"
        case .fourPlayerX:
            return "Four Player Chess with an X"
        }
    }
}

class ChessGameVC: GameVC {
    init(chessVariation: ChessVariation, gameView: UIView) {
        switch chessVariation {
        case .fourPlayer:
            // create the board
            let chessBoard = Board(numRows: 12, numColumns: 12, skipCells: [0, 1 ,10, 11, 12, 13, 22, 23, 120, 121, 130, 131, 132, 133, 142, 143])
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation, board: chessBoard), ChessPlayer(index: 1, variation: chessVariation, board: chessBoard), ChessPlayer(index: 2, variation: chessVariation, board: chessBoard), ChessPlayer(index: 3, variation: chessVariation, board: chessBoard)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
            
        case .fourPlayerX:
            // create the board
            let chessBoard = Board(numRows: 12, numColumns: 12, skipCells: [0, 1 ,10, 11, 12, 13, 22, 23, 120, 121, 130, 131, 132, 133, 142, 143, 39, 52, 91, 104, 44, 55, 88, 99])
            //65, 78, 66, 77, 
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation, board: chessBoard), ChessPlayer(index: 1, variation: chessVariation, board: chessBoard), ChessPlayer(index: 2, variation: chessVariation, board: chessBoard), ChessPlayer(index: 3, variation: chessVariation, board: chessBoard)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
        case .standardChess:
            // create the board
            let chessBoard = Board(numRows: 8, numColumns: 8)
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation, board: chessBoard), ChessPlayer(index: 1, variation: chessVariation, board: chessBoard)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
        }
    }
    
    override func checkForGameOver(){
        
        // check if next player is in check, display string
        let player = game.players[game.nextTurn]
        if isCheck(player, game: nil) {
            let message = player.name != nil ? (player.name! + " is in check") : "in check"
            presenterDelegate?.secondaryGameMessage(string: message)
        } else {
            presenterDelegate?.secondaryGameMessage(string: "")
        }
        
        // check if any player is in checkmate
        var playersInCheckMate = [Player]()
        for player in game.players {
            if player.id != game.players[game.whoseTurn].id {
                if isCheckMate(player, game: game.copy()) {
                    playersInCheckMate.append(player)
                }
            }
        }
        if playersInCheckMate.count > 0 {
            var message = (playersInCheckMate[0].name ?? "")
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
    
    func isCheck(_ player: Player, game: Game?) -> Bool {

        // all other players pieces can not take king
        var isCheck = false
        let player = game?.players.elementPassing({$0.id == player.id}) ?? player
        let game = game ?? self.game
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

    func isCheckMate(_ player: Player, game: Game?) -> Bool {
        
        // after a move, check next player for checkmate if in check
        // if in check, can use any piece to get out of check?
        // if game.isCheck check all translations pieces can move
        var isCheckMate = false
        if isCheck(player, game: game) {
            let game = game ?? self.game
            var canMoveOutOfCheck = false
            for piece in player.pieces where canMoveOutOfCheck == false {
                for index in game.board.indexesNotSkipped {
                    let position = game.board.position(index: index)
                    let translation = Position.calculateTranslation(fromPosition: piece.position, toPosition: position, direction: player.forwardDirection)
                    if piece.isPossibleTranslation(translation) {   // eliminate some iterations
                        let moveFunction = piece.isLegalMove(translation)
                        if moveFunction.isLegal {
                            let isMetAndCompletions = game.checkIfConditionsAreMet(piece: piece, legalIfs: moveFunction.legalIf)
                            if isMetAndCompletions.isMet {
                                // if piece is moved, come out of check?
                                let gameCopy = game.copy()
                                gameCopy.movePieceMatching(piece: piece, position: position, removeOccupying: piece.removePieceOccupyingNewPosition)
                                for completion in isMetAndCompletions.completions ?? [] {
                                    completion.closure()
                                }
                                if isCheck(player, game: gameCopy) == false {
                                    canMoveOutOfCheck = true
                                }
                            } else if let completionsEvenIfNotMet = isMetAndCompletions.completions?.filter({$0.evenIfNotMet}) {
                                let gameCopy = game.copy()
                                for completion in completionsEvenIfNotMet {
                                    if completion.evenIfNotMet {
                                        completion.closure()
                                    }
                                }
                                if isCheck(player, game: gameCopy) == false {
                                    canMoveOutOfCheck = true
                                }
                            }
                        }
                    }
                }
            }
            if canMoveOutOfCheck == false {
                isCheckMate = true
            }
        }
        return isCheckMate
    }
}













