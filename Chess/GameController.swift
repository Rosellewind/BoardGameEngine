//
//  GameController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

////// stopped here, next add taps, which square/position, which piece matches position, select it(var), next tap, if selected, ask piece if legalMove, check that conditions are met, animate piece to new spot, remove any if called for

import UIKit

enum ChessVariation {
    case StandardChess, Galaxy
}
class GameController {
    let board: Board
    let boardView: BoardView
    let players: [Player]
    var pieceViews = [PieceView]()
    var selectedPiece: Piece?
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
                    let ending = player.orientation == .bottom ? "Black.png" : "White.png"////add images
                    if let image = UIImage(named: piece.name + "Black.png") {
                        let pieceView = PieceView(image: image, startingPoint: CGPointZero)
                        pieceViews.append(pieceView)
                        let indexOfPieceOnBoard = board.index(piece.position)
                        let correctCells = boardView.cells.filter({ (view: UIView) -> Bool in
                            if indexOfPieceOnBoard == view.tag {////////check tag
                                return true
                            } else {
                                return false
                            }
                        })
                        if correctCells.count > 0 {
                            let cell = correctCells[0]
                            gameView.addSubview(pieceView)
                            pieceView.translatesAutoresizingMaskIntoConstraints = false
                            let widthConstraint = NSLayoutConstraint(item: pieceView, attribute: .Width, relatedBy: .Equal, toItem: boardView.cells[0], attribute: .Width, multiplier: 1, constant: 0)
                            let heightConstraint = NSLayoutConstraint(item: pieceView, attribute: .Height, relatedBy: .Equal, toItem: boardView.cells[0], attribute: .Height, multiplier: 1, constant: 0)
                            let positionX = NSLayoutConstraint(item: pieceView, attribute: .CenterX, relatedBy: .Equal, toItem: cell, attribute: .CenterX, multiplier: 1, constant: 0)
                            let positionY = NSLayoutConstraint(item: pieceView, attribute: .CenterY, relatedBy: .Equal, toItem: cell, attribute: .CenterY, multiplier: 1, constant: 0)
                            NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, positionX, positionY])
                        }
                    }
                }
            }
            
            // add taps to cells on boardView
            boardView.cells.forEach({ (view: UIView) in
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GameController.cellTapped(_:))))
            })
            
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
        if let view = sender.view {
            let position = board.position(view.tag)
            let piece = pieceForPosition(position)
            
            // beginning of turn, selecting the piece
            if selectedPiece == nil {
                // get the piece
                if piece != nil {// cell must be occupied for selection //////////pieceView listen to selection
                    piece!.selected = true
                    selectedPiece = piece
                }
            }
            
            // final part of turn, choosing where to go
            else {
                let translation = calculateTranslation(selectedPiece!.position, toPosition: position, orientation: players[whoseTurn].orientation)
                let move = selectedPiece!.isLegalMove(translation: translation)
                if move.isLegal {
                    var isStillLegal = true
                    if let conditions = move.conditions {
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
                            }
                        }
                    }
                    if isStillLegal {
                        if piece != nil {
                            // remove it, score///////////
                        }
                        print("legal move")
                        // move the piece into new position, or listen to position change and change position
//                        UIView.animateWithDuration(2.0, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
//                            pieceViews.filter({ (<#PieceView#>) -> Bool in
//                                $0.
//                            })
//                            }, completion: nil)
                        
                        whoseTurn += 1
                    }
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
}
