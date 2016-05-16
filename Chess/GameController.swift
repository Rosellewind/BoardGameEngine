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
//    let players: [Player]
    
    init(variation: ChessVariation, gameView: UIView) {
        switch variation {
        case .StandardChess:
            
            // create the board
            board = Board(numRows: 8, numColumns: 8, skipCells: nil, checkered: true)
            
            // create the boardView
            boardView = BoardView(board: board, images: nil, colors: [UIColor.redColor(), UIColor.blackColor()])
            
            // add the view
            gameView.addSubview(boardView)
//            boardView.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(boardView))
            
            // create the players
//            players = [Player(orientation: .bottom, pieces: ), Player(orientation: .bottom, pieces: )]
            
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
            
        }
       
    }
}
