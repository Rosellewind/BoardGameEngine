//
//  GameController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

////// stopped here, next add taps, which square/position, which piece matches position, select it(var), next tap, if selected, ask piece if legalMove, check that conditions are met, animate piece to new spot, remove any if called for

//// pieceView tags aren't working, double


import UIKit

enum ChessVariation {
    case StandardChess, Galaxy
}

enum TurnCondition {
    case CantExposeKing
}

class GameController {
    let board: Board
    let boardView: BoardView
    let players: [Player]
    var pieceViews = [PieceView]()
    var selectedPiece: Piece?
    var turnConditions: [TurnCondition]?
    var whoseTurn: Int = 0 {
        didSet {
            if whoseTurn >= players.count {
                whoseTurn = 0
            }
        }
    }
    
    init(variation: ChessVariation, gameView: UIView) {
        switch variation {
        case .StandardChess:
            
            // create the board
            board = Board(numRows: 8, numColumns: 8, skipCells: nil, checkered: true)
            
            // create the boardView
            boardView = BoardView(board: board, images: nil, colors: [UIColor.redColor(), UIColor.blackColor()])
            
            // add the boardView
            gameView.addSubview(boardView)
            boardView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(boardView))

            // create the players with pieces
            players = [Player(variation: .StandardChess, orientation: .bottom), Player(variation: .StandardChess, orientation: .top)]
            
            // create pieceView's
            for player in players {
                for piece in player.pieces {///////need a tag?
                    let ending = player.orientation == .bottom ? "Black" : "White"////add images
                    if let image = UIImage(named: piece.name + ending) {
                        let pieceView = PieceView(image: image)
                        pieceView.tag = piece.tag
                        pieceView.observing = [(piece, "selected")]
                        pieceViews.append(pieceView)
                        let indexOfPieceOnBoard = board.index(piece.position)
                        if let cell = boardView.cells.elementPassing({return indexOfPieceOnBoard == $0.tag}) {
                            boardView.addSubview(pieceView)
                            pieceView.translatesAutoresizingMaskIntoConstraints = false
                            let widthConstraint = NSLayoutConstraint(item: pieceView, attribute: .Width, relatedBy: .Equal, toItem: boardView.cells[0], attribute: .Width, multiplier: 1, constant: 0)
                            let heightConstraint = NSLayoutConstraint(item: pieceView, attribute: .Height, relatedBy: .Equal, toItem: boardView.cells[0], attribute: .Height, multiplier: 1, constant: 0)
                            let positionX = NSLayoutConstraint(item: pieceView, attribute: .CenterX, relatedBy: .Equal, toItem: cell, attribute: .CenterX, multiplier: 1, constant: 0)
                            let positionY = NSLayoutConstraint(item: pieceView, attribute: .CenterY, relatedBy: .Equal, toItem: cell, attribute: .CenterY, multiplier: 1, constant: 0)
                            pieceView.positionConstraints = [positionX, positionY]
                            NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, positionX, positionY])
                        }
                    }
                }
            }
            
            // add taps to cells on boardView
            boardView.cells.forEach({ (view: UIView) in
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GameController.cellTapped(_:))))
            })
            
            // add turn conditions
            
        case .Galaxy:
            // create the board
            board = Board(numRows: 8, numColumns: 5, skipCells: [0, 4, 20], checkered: true)
            
            // create the boardView
            var images = [UIImage]()
            for i in 1...3 {
                if let image = UIImage(named: "\(i).jpg") {
                    images.append(image)
                }
            }
            boardView = BoardView(board: board, images: images, colors: nil)
            
            // add the view
            gameView.addSubview(boardView)
            boardView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(boardView))
            
            // create the players with pieces
            players = [Player(variation: .Galaxy, orientation: .bottom)]
            
        }
       
    }
    
    @objc func cellTapped(sender: UITapGestureRecognizer) {
        print("cellTapped")
        if let view = sender.view {
            let position = board.position(view.tag)
            let piece = pieceForPosition(position)
            
            // beginning of turn, selecting the piece
            let isBeginningOfTurn = selectedPiece == nil
            if isBeginningOfTurn {
                // get the piece
                if piece != nil {// cell must be occupied for selection
                    let isPlayersOwnPiece = players[whoseTurn].pieces.contains(piece!)
                    if isPlayersOwnPiece {
                        piece!.selected = true  ////// necessary?
                        selectedPiece = piece
                    }
                }
            }
            
            // final part of turn, choosing where to go
            else {/////////conditions required, make protocol
                let translation = calculateTranslation(selectedPiece!.position, toPosition: position, orientation: players[whoseTurn].orientation)
                let moveFunction = selectedPiece!.isLegalMove(translation: translation)
                if moveFunction.isLegal {
                    var isStillLegal = true
                    var markIsFirstMoveAsFalse = false
                    if let conditions = moveFunction.conditions {
                        for condition in conditions where isStillLegal == true {
                            switch condition.condition {
                            case .CantBeOccupied:
                                for translation in condition.positions {
                                    let positionToCheck = positionFromTranslation(translation, fromPosition: selectedPiece!.position, orientation: players[whoseTurn].orientation)
                                    let pieceOccupying = pieceForPosition(positionToCheck)
                                    if pieceOccupying != nil {
                                        isStillLegal = false
                                    }
                                }
                            ///pos to trans
                                
                            case .MustBeOccupied:
                                for translation in condition.positions {
                                    let positionToCheck = positionFromTranslation(translation, fromPosition: selectedPiece!.position, orientation: players[whoseTurn].orientation)
                                    let pieceOccupying = pieceForPosition(positionToCheck)
                                    if pieceOccupying == nil {
                                        isStillLegal = false
                                    }
                                }
                            case .MustBeOccupiedByOpponent:
                                for translation in condition.positions {
                                    let positionToCheck = positionFromTranslation(translation, fromPosition: selectedPiece!.position, orientation: players[whoseTurn].orientation)
                                    let pieceOccupying = pieceForPosition(positionToCheck)
                                    if pieceOccupying == nil {
                                        isStillLegal = false
                                    } else if players[whoseTurn].pieces.contains(pieceOccupying!) {
                                        isStillLegal = false
                                    }
                                }
                            case .CantBeOccupiedBySelf:
                                for translation in condition.positions {
                                    let positionToCheck = positionFromTranslation(translation, fromPosition: selectedPiece!.position, orientation: players[whoseTurn].orientation)
                                    let pieceOccupying = pieceForPosition(positionToCheck)
                                    if pieceOccupying != nil && players[whoseTurn].pieces.contains(pieceOccupying!) {
                                        isStillLegal = false
                                    }
                                }
                            case .OnlyInitialMove:
                                if !selectedPiece!.isFirstMove {
                                    isStillLegal = false
                                }
                            }
                        }
                    }
                    if isStillLegal {
                        // check turn conditions
                        if turnConditions != nil {
                            for condition in turnConditions! {
                                switch condition {
                                case .CantExposeKing:
                                    break
                                }
                            }
                        }
                        
                        
                        
                        if selectedPiece!.isFirstMove == true {
                            selectedPiece!.isFirstMove = false
                        }
                        if piece != nil {
                            // remove it, score///////////
                            
                            
                            if let match = pieceViews.elementPassing({$0.tag == piece!.tag}) {
                                match.removeFromSuperview()
                                for player in players {
                                    let index = player.pieces.indexOf(piece!)
                                    if index != nil {
                                        player.pieces.removeAtIndex(index!)
                                        
                                    }
                                }
                            }
                        }
                        print("legal move")
                        // move the piece into new position, or listen to position change and change position
                        animatePiece(selectedPiece!, position: position)
                        
                        selectedPiece!.selected = false
                        selectedPiece = nil
                        whoseTurn += 1
                    } else {
                        // delesect
                        selectedPiece!.selected = false
                        selectedPiece = nil
                    }
                } else {    // move is not legal
                    // delesect
                    selectedPiece!.selected = false
                    selectedPiece = nil
                }
            }
            

        }
    }
    
    func positionFromTranslation(translation: Position, fromPosition: Position, orientation: PlayerOrientation) -> Position {
        switch orientation {
        case .top:
            let row = fromPosition.row + translation.row
            let column = fromPosition.column + translation.column
            return Position(row: row, column: column)
        case .bottom:
            let row = fromPosition.row - translation.row////////check math
            let column = fromPosition.column + translation.column
            return Position(row: row, column: column)
        default:
            return Position(row: 0, column: 0) //// implement others later
        }
    }
    
    func calculateTranslation(fromPosition:Position, toPosition: Position, orientation: PlayerOrientation) -> Position {
        
        switch orientation {
        case .top:
            let row = toPosition.row - fromPosition.row
            let column = toPosition.column - fromPosition.column
            return Position(row: row, column: column)
        case .bottom:
            let row = fromPosition.row - toPosition.row
            let column = toPosition.column - fromPosition.column
            return Position(row: row, column: column)
        default:
            return Position(row: 0, column: 0) //// implement others later
        }
    }
    
    func pieceForPosition(position: Position) -> Piece? {
        var pieceFound: Piece?
        for player in players {
            for piece in player.pieces {
                if piece.position == position {
                    pieceFound = piece
                }
            }
        }
        return pieceFound
    }
    
    func animatePiece(piece: Piece, position: Position) {
        if let pieceView = pieceViews.elementPassing({$0.tag == piece.tag}) {
            // deactivate position constraints
            NSLayoutConstraint.deactivateConstraints(pieceView.positionConstraints)
            
            // activate new position constraints
            let cellIndex = board.index(position)
            let matchingCells = boardView.cells.filter({$0.tag == cellIndex})
            if matchingCells.count > 0 {
                let cell = matchingCells[0]
                let positionX = NSLayoutConstraint(item: pieceView, attribute: .CenterX, relatedBy: .Equal, toItem: cell, attribute: .CenterX, multiplier: 1, constant: 0)
                let positionY = NSLayoutConstraint(item: pieceView, attribute: .CenterY, relatedBy: .Equal, toItem: cell, attribute: .CenterY, multiplier: 1, constant: 0)
                pieceView.positionConstraints = [positionX, positionY]
                NSLayoutConstraint.activateConstraints(pieceView.positionConstraints)
            }
            
            // update piece position
            piece.position = position
            
            // animate the change
            boardView.setNeedsUpdateConstraints()
            UIView.animateWithDuration(0.5) {
                self.boardView.layoutIfNeeded()
            }
        }
    }
}
