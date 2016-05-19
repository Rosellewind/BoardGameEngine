//
//  GameController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

enum ChessVariation {
    case StandardChess, Galaxy
}
class GameController {
    let board: Board
    let boardView: BoardView
    let players: [Player]
    var pieceViews = [PieceView]()
    
    init(variation: ChessVariation, gameView: UIView) {
        switch variation {
        case .StandardChess:
            
            // create the board
            board = Board(numRows: 8, numColumns: 8, skipCells: nil, checkered: true)
            
            // create the boardView
            boardView = BoardView(board: board, images: nil, colors: [UIColor.redColor(), UIColor.blackColor()])
            
            // add the view
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
                        let pieceView = PieceView(image: image)
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
                            correctCells[0].addSubview(pieceView)
                            pieceView.translatesAutoresizingMaskIntoConstraints = false
                            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(pieceView))
                        }
                        
                    }
                }
            }
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
}
