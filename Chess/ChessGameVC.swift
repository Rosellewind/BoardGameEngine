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
            let chessBoard = Board(numRows: 8, numColumns: 8, skipCells: nil)
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation, board: chessBoard), ChessPlayer(index: 1, variation: chessVariation, board: chessBoard)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
        }
    }
    
    override func checkForGameOver(){
        var playersInCheck = [Player]()
        var playersInCheckMate = [Player]()
        
        // determine in player are in check or checkmate
        for player in game.players {
            // check for in check
            if isCheck(player, game: nil) {
                if isCheckMate(player, game: nil) {
                    playersInCheckMate.append(player)
                } else {
                    playersInCheck.append(player)
                }
            }
            
        }
        
        // show message for players in check
        if playersInCheck.count > 0 {
            var message = ""
            if playersInCheck.count == 1 {
                message.append("\(playersInCheck[0].name!) is in check")
            } else if playersInCheck.count > 1 {
                message.append("\(playersInCheck[0].name!)")
                for i in 1..<playersInCheck.count {
                    message.append(" and \(playersInCheck[i].name!)")
                }
                message.append(" are in check")
            }
            presenterDelegate?.secondaryGameMessage(string: message)
        } else {
            presenterDelegate?.secondaryGameMessage(string: "")
        }
        
        // show message for players in checkmate
        if playersInCheckMate.count > 0 {
            var message = ""
            if playersInCheckMate.count == 1 {
                message.append("\(playersInCheckMate[0].name!) is in checkmate!")
            } else {
                message.append("\(playersInCheckMate[0].name!)")
                for i in 1..<playersInCheckMate.count {
                    message.append(" and \(playersInCheckMate[i].name!)")
                }
                message.append(" are in checkmate!")
            }
            presenterDelegate?.gameMessage(message, status: .gameOver)
        }
     }
    
    func isCheck(_ player: Player, game: Game?, callingFunctionName: String = #function) -> Bool {
print("Calling Function: \(callingFunctionName)")
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
                        var moveFunction = otherPlayerPiece.isLegalMove(translationToCaptureKing)
                        if moveFunction.isLegal {
                            // if called from isCheckMate, remove the CantBeInCheck condition for other player
                            if callingFunctionName == "isCheckMate(_:game:)", let index = moveFunction.legalIf?.index(where: {($0.condition as? CantBeInCheck) != nil}) {
                                moveFunction.legalIf!.remove(at: index)
                            }
                            
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













