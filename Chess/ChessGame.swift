//
//  AllChess.swift
//  ChessGame
//
//  Created by Roselle Milvich on 6/13/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


enum ChessVariation: Int {
    case standardChess, holeChess, fourPlayer, fourPlayerX, galaxyChess
    static let allValues = [standardChess, holeChess, fourPlayer, fourPlayerX, galaxyChess]
    func name() -> String {
        switch self {
        case .standardChess:
            return "Chess"
        case .holeChess:
            return "Chess with a Hole"
        case .fourPlayer:
            return "Four Player Chess"
        case .fourPlayerX:
            return "Four Player Chess with an X"
        case .galaxyChess:
            return "Galaxy Chess"
        }
    }
}

class ChessGame: Game {
    init(chessVariation: ChessVariation, gameView: UIView) {
        switch chessVariation {
        case .fourPlayer:

            // create the board
            let chessBoard = Board(numRows: 12, numColumns: 12, emptyCells: [0, 1 ,10, 11, 12, 13, 22, 23, 120, 121, 130, 131, 132, 133, 142, 143])
            
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation.rawValue), ChessPlayer(index: 1, variation: chessVariation.rawValue), ChessPlayer(index: 2, variation: chessVariation.rawValue), ChessPlayer(index: 3, variation: chessVariation.rawValue)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
            
        case .fourPlayerX:
            // create the board
            let chessBoard = Board(numRows: 12, numColumns: 12, emptyCells: [0, 1 ,10, 11, 12, 13, 22, 23, 120, 121, 130, 131, 132, 133, 142, 143, 39, 52, 91, 104, 44, 55, 88, 99])
            //65, 78, 66, 77, 
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation.rawValue), ChessPlayer(index: 1, variation: chessVariation.rawValue), ChessPlayer(index: 2, variation: chessVariation.rawValue), ChessPlayer(index: 3, variation: chessVariation.rawValue)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
        case .standardChess, .galaxyChess:
            
            // create the board
            let chessBoard = Board(numRows: 8, numColumns: 8)
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation.rawValue), ChessPlayer(index: 1, variation: chessVariation.rawValue)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
        case .holeChess:
            // create the board
            let chessBoard = Board(numRows: 8, numColumns: 8, emptyCells: [27, 28, 35, 36])
            
            // create the boardView
            let chessBoardView = BoardView(board: chessBoard, checkered: true, images: nil, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let chessPlayers = [ChessPlayer(index: 0, variation: chessVariation.rawValue), ChessPlayer(index: 1, variation: chessVariation.rawValue)]
            
            super.init(gameView: gameView, board: chessBoard, boardView: chessBoardView, players: chessPlayers)
        }
    }
    
    override func checkForGameOver(){
        let player = players[whoseTurn]
        if isCheck(player, snapshot: nil) {
            let message = player.name != nil ? (player.name! + " is in check") : "in check"
            presenterDelegate?.secondaryGameMessage(string: message)
        } else {
            presenterDelegate?.secondaryGameMessage(string: "")
        }
        var playersInCheckMate = [Player]()
        for player in players {
            if player.id != players[whoseTurn].id {
                if isCheckMate(player, snapshot: nil) {
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
    
    func isCheck(_ player: Player, snapshot: GameSnapshot?) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        let thisPlayer = snapshot?.players.elementPassing({$0.id == player.id}) ?? player
        let thisPlayers = snapshot?.players ?? players
        if let king = thisPlayer.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in thisPlayers where isCheck == false {
                if otherPlayer === thisPlayer {
                    continue
                } else {
                    for otherPlayerPiece in otherPlayer.pieces where isCheck == false {
                        let translation = Position.calculateTranslation(fromPosition: otherPlayerPiece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = otherPlayerPiece.isLegalMove(translation)
//                        isCheck = moveFunction.isLegal && pieceConditionsAreMet(otherPlayerPiece, conditions: moveFunction.conditions, snapshot: snapshot).isMet
                    }
                }
            }
        }
        return isCheck
    }
    // midTurn, between moves,
    func isCheckMate(_ player: Player, snapshot: GameSnapshot?) -> Bool {
        
        // after a move, check next player for checkmate if in check
        // if in check, can use any piece to get out of check?
//        if snapshot.isCheck
//        check all translations pieces can move
//        var isCheckMate = false
//        if isCheck(player, snapshot: snapshot) {
//            isCheckMate = true
//            for piece in player.pieces where isCheckMate == true {
//                for index in board.indexesNotEmpty {
//                    let position = board.position(index: index)
//                    let translation = Position.calculateTranslation(fromPosition: piece.position, toPosition: position, direction: player.forwardDirection)
//                    if piece.isPossibleTranslation(translation) {   // eliminate some iterations
//                        self.reusableGameSnapshot = GameSnapshot(game: self)//not using snapshot para
//                        let moveFunction = piece.isLegalMove(translation)
//                        let pieceConditions = pieceConditionsAreMet(piece, conditions: moveFunction.conditions, snapshot: self.reusableGameSnapshot)
//                        
//                        if moveFunction.isLegal && pieceConditions.isMet {
//                            
//                            // remove occupying piece if needed
//                            let occupyingPiece = pieceForPosition(position, snapshot: self.reusableGameSnapshot)
//                            if piece.removePieceOccupyingNewPosition == true && occupyingPiece != nil {
//                                self.reusableGameSnapshot?.makeMove(Move(piece: occupyingPiece!, remove: true, position: nil))
//                            }
//                            
//                            // move the piece
//                            self.reusableGameSnapshot?.makeMove(Move(piece: piece, remove: false, position: position))
//                            
//                            // completions
//                            if let completions = pieceConditions.completions {
//                                for completion in completions {
//                                    completion()
//                                }
//                            }
//                        
//                            if isCheck(player, snapshot: self.reusableGameSnapshot) == false {
//                                isCheckMate = false
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        return isCheckMate
        return false
    }
    
    fileprivate func promote(piece: Piece, toType: ChessPieceType) {
        // create replacement
        let newPiece = ChessPieceCreator.shared.chessPiece(toType)
        newPiece.position = piece.position
        newPiece.id = piece.id
        newPiece.isFirstMove = piece.isFirstMove
        newPiece.startingPosition = piece.startingPosition
        newPiece.player = piece.player
        newPiece.selected = piece.selected
        
        // remove the old and add the new
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
            self.removePieceAndViewFromGame(piece: piece)
            self.addPieceAndViewToGame(piece: newPiece)
            }, completion: nil)
//        UIView.animate(withDuration: 0.2, animations: removePieceAndViewFromGame(piece: piece)
//            addPieceAndViewToGame(piece: newPiece))
        
    }
}













