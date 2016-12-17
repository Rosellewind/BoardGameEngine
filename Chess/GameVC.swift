//
//  GameVC.swift
//  Chess
//
//  Created by Roselle Tanner on 12/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class GameVC: PieceViewProtocol {
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
        
        // pieceView layout and observing
        setupLayoutAndObservingForPieceViews(pieceViews: pieceViews)
        
        // add taps to cells on boardView
        boardView.cells.forEach({ (view: UIView) in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GameVC.cellTapped(_:))))
        })
        
        
    }
    
    /// creates a default board for testing purposes
    convenience init(gameView: UIView) {
        
        // create the board
        let defaultBoard = Board(numRows: 8, numColumns: 5, emptyCells: [0, 4, 20])
        
        // create the boardView
        var images = [UIImage]()
        for i in 1...3 {
            if let image = UIImage(named: "\(i).jpg") {
                images.append(image)
            }
        }
        let defaultBoardView = BoardView(board: defaultBoard, checkered: false, images: images, backgroundColors: nil)
        
        // create the players with pieces
        let isPossibleTranslation: (Translation) -> Bool = {_ in return true}
        let defaultPlayers = [Player(name: "alien", id: 0, forwardDirection: .top, pieces: [Piece(name: "hi", position: Position(row: 0,column: 0), isPossibleTranslation: isPossibleTranslation, isLegalMove: {_ in return (true, nil)})])]
        
        // create pieceView's
        self.init(gameView: gameView, board: defaultBoard, boardView: defaultBoardView, players: defaultPlayers)
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
                let imageView = PieceView(image: image, pieceTag: piece.id)
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat(radians))
                return imageView
            }
        }
        
        return nil
    }
    
    func setupLayoutAndObservingForPieceViews(pieceViews: [PieceView]) {
        // pieceView layout and observing
        for pieceView in pieceViews {
            setupLayoutAndObservingForPieceView(pieceView: pieceView)
        }
    }
    
    func setupLayoutAndObservingForPieceView(pieceView: PieceView) {
        if let piece = game.piece(tag: pieceView.tag) {
            // add delegate
            pieceView.delegate = self
            // add observing
            pieceView.observing = [(piece, "selected"), (piece, "position")]
            
            // pieceView layout
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
                        
                        // move the piece
                        game.movePiece(piece: game.selectedPiece!, position: positionTapped, removeOccupying: false)
                        
                        
                        // completions
                        if let completions = isMetAndCompletions.completions {
                            for completion in completions {
                                completion()
                            }
                        }
                        
                        // check for gameOver
                        checkForGameOver()
                        game.whoseTurn += 1
                        presenterDelegate?.gameMessage((game.players[game.whoseTurn].name ?? "") + "'s turn", status: .whoseTurn)
                    } else {
                        if let completions = isMetAndCompletions.completions {
                            for completion in completions {
                                completion()
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
                setupLayoutAndObservingForPieceView(pieceView: pieceView)
            }
        }
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

