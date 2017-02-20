//
//  GameVC.swift
//  Chess
//
//  Created by Roselle Tanner on 12/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

protocol GameVariation {
    func screenName() -> String
}

enum UniqueVariation: GameVariation {
    case galaxy, blackHole
    static let allValues = [galaxy, blackHole]
    func screenName() -> String {
        switch self {
        case .galaxy:
            return "Galaxy Game"
        case .blackHole:
            return "Black Hole"
        }
    }
}

class GameVC {
    var game: Game
    var boardView: BoardView
    var pieceViews: [PieceView] = [PieceView]()
    weak var presenterDelegate: GamePresenterProtocol? {
        didSet {
            presenterDelegate?.gameMessage((game.players[game.whoseTurn].name ?? "") + " Starts!", status: .whoseTurn)
        }
    }
    
    //    var reusableGameCopy: Game?
    
    
    init(gameView: UIView, board: Board, boardView: BoardView, players: [Player]) {
        self.game = Game(board: board, players: players)
        self.boardView = boardView
        self.pieceViews = makePieceViews(players: players)
        
        self.game.vc = self
        
        // boardView layout
        gameView.addSubview(boardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(NSLayoutConstraint.bindTopBottomLeftRight(boardView))
        
//        // pieceView layout
        setupLayoutForPieceViews(pieceViews: pieceViews)
        
        // add taps to cells on boardView
        boardView.cells.forEach({ (view: UIView) in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GameVC.cellTapped(_:))))
        })
        
        
    }
    
    /// creates a default board for testing purposes
    convenience init(gameVariation: UniqueVariation, gameView: UIView) {
        switch gameVariation {
        case .galaxy:
            // create the board
            let board = Board(numRows: 8, numColumns: 8, skipCells: nil)
            
            // create the boardView
            let image1 = UIImage(named: "galaxy1")
            let image2 = UIImage(named: "galaxy2")
            let images = (image1 != nil && image2 != nil) ? [image1!, image2!] : nil
            let boardView = BoardView(board: board, checkered: true, images: images, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces   // set forwardDirection elsewhere, by index in players/playerId
            let players = [Player(name: "Green", id: 0, forwardDirection: .right, pieces: PieceCreator.shared.makePieces(variation: gameVariation, playerId: 0, board: board)), Player(name: "Orange", id: 1, forwardDirection: .left, pieces: PieceCreator.shared.makePieces(variation: gameVariation, playerId: 1, board: board))]
            
            self.init(gameView: gameView, board: board, boardView: boardView, players: players)
        case .blackHole:
            // create the board
            let board = Board(numRows: 10, numColumns: 10, skipCells: Set(Board.octoganalSkips(across: 10)))

            // create the boardView
            let image1 = UIImage(named: "galaxy1")
            let image2 = UIImage(named: "galaxy2")
            let images = (image1 != nil && image2 != nil) ? [image1!, image2!] : nil
            let boardView = BoardView(board: board, checkered: true, images: images, backgroundColors: [UIColor.red, UIColor.black])
            
            // create the players with pieces
            let players = [Player(name: "Green", id: 0, forwardDirection: .right, pieces: PieceCreator.shared.makePieces(variation: gameVariation, playerId: 0, board: board)), Player(name: "Orange", id: 1, forwardDirection: .left, pieces: PieceCreator.shared.makePieces(variation: gameVariation, playerId: 1, board: board))]
            
            // adjust pieces starting positions
            for player in players {
                switch player.forwardDirection {
                case .right:
                    for piece in player.pieces {
                        let offset = piece.position.column
                        piece.position = Position(row: piece.position.row, column: board.columnFromFromNonSkippedEdge(row: piece.position.row, offset: offset, fromTheLeft: true) ?? 0)
                        piece.startingPosition = piece.position
                    }
                case .left:
                    for piece in player.pieces {
                        let offset = piece.position.column - (board.numColumns - 1)
                        piece.position = Position(row: piece.position.row, column: board.columnFromFromNonSkippedEdge(row: piece.position.row, offset: offset, fromTheLeft: false) ?? 0)
                        piece.startingPosition = piece.position
                    }
                case .top:
                    for piece in player.pieces {
                        let offset = piece.position.row
                        piece.position = Position(row: board.rowFromNonSkippedEdge(column: piece.position.column, offset: offset, fromTheTop: false) ?? 0, column: piece.position.column)
                        piece.startingPosition = piece.position
                    }
                case .bottom:
                    for piece in player.pieces {
                        let offset = piece.position.row - (board.numRows - 1)
                        piece.position = Position(row: board.rowFromNonSkippedEdge(column: piece.position.column, offset: offset, fromTheTop: true) ?? 0, column: piece.position.column)
                        piece.startingPosition = piece.position
                    }
                }
            }
            self.init(gameView: gameView, board: board, boardView: boardView, players: players)
            
            //            let tenByTenOctagon = [0, 1, 2, 7, 8, 9, 10, 11, 18, 19, 20, 29, 70, 79, 80, 81, 88, 89, 90, 91, 92, 97, 98, 99]
        }
    }
    
    deinit {
        print("deinit GameVC")
    }
    
    func makePieceViews(players: [Player]) -> [PieceView] {
        var pieceViews = [PieceView]()
        for player in players {
            for piece in player.pieces {
                if let pieceView = makePieceView(piece: piece) {
                    pieceViews.append(pieceView)
                }
            }
        }
        return pieceViews
    }
    
    func makePieceView(piece: Piece) -> PieceView? {
        if let player = piece.player {
            let name = piece.name + (player.name ?? "")
            var radians: Double
            switch player.forwardDirection {
            case .top:
                radians = 0
            case .bottom:
                radians = M_PI
            case .left:
                radians = M_PI_2 * -1
            case .right:
                radians = M_PI_2
            }
            if let image = UIImage(named: name) {
                let pieceView = PieceView(image: image, pieceTag: piece.id)
                pieceView.transform = CGAffineTransform(rotationAngle: CGFloat(radians))
                piece.pieceView = pieceView
                return pieceView
            }
        }
        
        return nil
    }
    
    func setupLayoutForPieceViews(pieceViews: [PieceView]) {////forall()
        // pieceView layout
        for pieceView in pieceViews {
            setupLayoutForPieceView(pieceView: pieceView)
        }
    }
    
    func setupLayoutForPieceView(pieceView: PieceView) {
        if let piece = game.piece(tag: pieceView.tag) {
            let indexOfPieceOnBoard = game.board.index(position: piece.position)
            if let cell = boardView.cells.elementPassing({return indexOfPieceOnBoard == $0.tag}) {
                boardView.addSubview(pieceView)
                pieceView.constrainToCell(cell)
            }
        }
    }
    
    func checkForGameOver() {
        for player in game.players {
            if player.pieces.count == 0 {
                presenterDelegate?.gameMessage("Game Over", status: .gameOver)
            }
        }
    }
}


// MARK: Game Logic

extension GameVC {
    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        if let view = sender.view {
            let positionTapped = game.board.position(index: view.tag)
            let pieceTapped = game.piece(position: positionTapped)
            
            // beginning of turn, selecting the piece
            let isBeginningOfTurn = game.selectedPiece == nil
            if isBeginningOfTurn {
                // get the piece
                if pieceTapped != nil {// cell must be occupied for selection
                    let isPlayersOwnPiece = game.players[game.whoseTurn].pieces.contains(pieceTapped!)
                    if isPlayersOwnPiece {
                        pieceTapped!.selected = true
                        game.selectedPiece = pieceTapped
                    }
                }
            }
                
                // final part of turn, choosing where to go, selectedPiece is not nil
            else {
                let translation = Position.calculateTranslation(fromPosition: game.selectedPiece!.position, toPosition: positionTapped, direction: game.players[game.whoseTurn].forwardDirection)
                let moveFunction = game.selectedPiece!.isLegalMove(translation)
                if moveFunction.isLegal {
                    // check
                    let isMetAndCompletions = game.checkIfConditionsAreMet(piece: game.selectedPiece!, legalIfs: moveFunction.legalIf)
                    if isMetAndCompletions.isMet {
                        // remove occupying piece if needed     // put in condition: removeOccupying, completions: removeOccupying
                        if game.selectedPiece!.removePieceOccupyingNewPosition == true && pieceTapped != nil {
                            removePieceAndViewFromGame(piece: pieceTapped!)
                        }
                        
                        // move the piece       /////////selectedPiece! guard
                        game.movePiece(piece: game.selectedPiece!, position: positionTapped, removeOccupying: false)
                        if let pieceView = game.selectedPiece!.pieceView {
                            animateMove(pieceView, position: game.selectedPiece!.position, duration: 0.5)

                        }
                        
                        
                        // completions
                        if let completions = isMetAndCompletions.completions {
                            for completion in completions {
                                completion.closure()
                            }
                        }
                        
                        // check for gameOver
                        checkForGameOver()
                        game.whoseTurn += 1
                        presenterDelegate?.gameMessage((game.players[game.whoseTurn].name ?? "") + "'s turn", status: .whoseTurn)
                    } else {
                        if let completions = isMetAndCompletions.completions {
                            for completion in completions {
                                if completion.evenIfNotMet {
                                    completion.closure()
                                }
                            }
                        }
                    }
                }
                game.selectedPiece!.selected = false
                game.selectedPiece = nil
            }
        }
    }
}

// MARK: Moving Pieces

extension GameVC {
    func removePieceAndViewFromGame(piece: Piece) {
        for player in game.players {
            if let index = player.pieces.index(of: piece) {
                if let pieceViewToRemove = pieceViews.elementPassing({$0.tag == piece.id}) {
                    pieceViewToRemove.removeFromSuperview()
                }
                player.pieces.remove(at: index)
            }
        }
    }
    
    func addPieceAndViewToGame(piece: Piece) {
        if let player = piece.player {
            player.pieces.append(piece)
            if let pieceView = makePieceView(piece: piece) {
                setupLayoutForPieceView(pieceView: pieceView)
            }
        }
    }
    
    func removeCellAndViewFromGame(position: Position) {
        for piece in game.pieces(position: position) ?? [] {
            removePieceAndViewFromGame(piece: piece)
        }
        let boardPosition = game.board.index(position: position)
        if let x = boardView.cells.elementPassing({$0.tag == boardPosition}) {
            x.isHidden = true
        }
        game.board.skipCells?.insert(boardPosition)
    }
    
    func animateMove(_ pieceView: PieceView, position: Position, duration: TimeInterval) {
        
        // deactivate position constraints
        NSLayoutConstraint.deactivate(pieceView.positionConstraints)
        
        // activate new position constraints matching cell constraints
        let cellIndex = game.board.index(position: position)
        if let cell = boardView.cells.elementPassing({$0.tag == cellIndex}) {
            let positionX = NSLayoutConstraint(item: pieceView, attribute: .centerX, relatedBy: .equal, toItem: cell, attribute: .centerX, multiplier: 1, constant: 0)
            let positionY = NSLayoutConstraint(item: pieceView, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0)
            pieceView.positionConstraints = [positionX, positionY]
            NSLayoutConstraint.activate(pieceView.positionConstraints)
        }
        
        // animate the change
        boardView.setNeedsUpdateConstraints()
        UIView.animate(withDuration: duration, animations: {
            self.boardView.layoutIfNeeded()
        })
    }
    
    func replacePieceAndView(piece piece1: Piece, withPiece piece2: Piece) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
            self.removePieceAndViewFromGame(piece: piece1)
            self.addPieceAndViewToGame(piece: piece2)
        }, completion: nil)
    }
    
}

