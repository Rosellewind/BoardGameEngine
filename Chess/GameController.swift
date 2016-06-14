//
//  GameController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

//// end of game, king can't be captured
//// castling, en passant, pawn promotion, check/mate
//// in Piece.isValidMove(), return optional positions
//// further the momento pattern


import UIKit

enum ChessVariation {
    case StandardChess, Galaxy
}

enum TurnCondition {
    case CantExposeKing, Castling
}

enum GameStatus {
    case GameOver, WhoseTurn, IllegalMove, Default
}

protocol GameControllerProtocol {
    func gameMessage(string: String, status: GameStatus?)
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
    var nextTurn: Int {
        get {
            var next = whoseTurn + 1
            if next >= players.count {
                next = 0
            }
            return next
        }
    }
    var statusDelegate: GameControllerProtocol? {
        didSet {
            statusDelegate?.gameMessage("White Starts!", status: .WhoseTurn)
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
                for piece in player.pieces {
                    let ending = player.orientation.colorString()
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
            turnConditions = [.CantExposeKing]
            
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
    
    func pieceConditionsAreMet(piece: Piece, player: Player, conditions: [(condition: LegalIfCondition, positions: [Position])]?) -> Bool {
        var conditionsAreMet = true
        for condition in conditions ?? [] where conditionsAreMet == true {
            switch condition.condition {
            case .CantBeOccupied:
                for translation in condition.positions {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, orientation: player.orientation)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying != nil {
                        conditionsAreMet = false
                    }
                }
                ///pos to trans
                
            case .MustBeOccupied:
                for translation in condition.positions {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, orientation: player.orientation)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying == nil {
                        conditionsAreMet = false
                    }
                }
            case .MustBeOccupiedByOpponent:
                for translation in condition.positions {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, orientation: player.orientation)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying == nil {
                        conditionsAreMet = false
                    } else if player.pieces.contains(pieceOccupying!) {
                        conditionsAreMet = false
                    }
                }
            case .CantBeOccupiedBySelf:
                for translation in condition.positions {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, orientation: player.orientation)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                        conditionsAreMet = false
                    }
                }
            case .IsInitialMove:
                if !piece.isFirstMove {
                    conditionsAreMet = false
                }
            case .RookIsInitialMove:
                if let rook = player.pieces.elementPassing({$0.name == "Rook"}) {
                    if rook.isFirstMove == false {
                        conditionsAreMet = false
                    }
                } else {
                    // if there is no rook, conditions are not met
                    conditionsAreMet = false
                }
            case .RookIsAlsoLegalMove:
                if let rook = player.pieces.elementPassing({$0.name == "Rook"}) {
                    for translation in condition.positions {
                        let moveFunction = rook.isLegalMove(translation: translation)
                        conditionsAreMet = pieceConditionsAreMet(rook, player: player, conditions: moveFunction.conditions)
                    }
                } else {
                    conditionsAreMet = false
                }
            case .CantBeInCheckDuring:
                break////****implement
            }
        }
        return conditionsAreMet
    }
    
    func turnConditionsAreMet(conditions: [TurnCondition]?) -> Bool {
        var conditionsAreMet = true
        for condition in conditions ?? [] {
            switch condition {
            case .CantExposeKing:////move to different file?
                if let king = players[whoseTurn].pieces.elementPassing({$0.name == "King"}) {
                    // for every opponents piece in new positions, can king be taken?
                    for piece in players[nextTurn].pieces where conditionsAreMet == true {
                        let translation = calculateTranslation(piece.position, toPosition: king.position, orientation: players[nextTurn].orientation)
                        let moveFunction = piece.isLegalMove(translation: translation)
                        if moveFunction.isLegal && pieceConditionsAreMet(piece, player: players[nextTurn], conditions: moveFunction.conditions){
                            conditionsAreMet = false
                        }
                    }
                }
            case .Castling://// ***king has just been marked as moving
                if selectedPiece?.name ?? "" == "King" && selectedPiece?.isFirstMove ?? false {
                    // 1. neither king nor rook has moved
                    if let rook = players[whoseTurn].pieces.elementPassing({$0.name == "Rook"}) {
                        if rook.isFirstMove {
                            // 2. there are no pieces between king and rook
                            
                            // 3. "One may not castle out of, through, or into check."
                        }
                    }
                    

                    
                }
            }
            
        }
        return conditionsAreMet
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
                        piece!.selected = true  //// necessary?
                        selectedPiece = piece
                    }
                }
            }
            
            // final part of turn, choosing where to go
            else {////conditions required, make protocol?
                let translation = calculateTranslation(selectedPiece!.position, toPosition: position, orientation: players[whoseTurn].orientation)
                let moveFunction = selectedPiece!.isLegalMove(translation: translation)
                if moveFunction.isLegal && pieceConditionsAreMet(selectedPiece!, player: players[whoseTurn], conditions: moveFunction.conditions) {
                    
                    // mark if first move and save momento
                    var momentoMarkedFirstMove = false
                    if selectedPiece!.isFirstMove == true {
                        selectedPiece!.isFirstMove = false
                        momentoMarkedFirstMove = true
                    }
                    
                    // remove piece if nedded and save momento
                    var momentoPieceRemoved: Piece?
                    var momentoPieceRemovedPlayer: Player?
                    if piece != nil {
                        momentoPieceRemoved = piece
                        for player in players where momentoPieceRemovedPlayer == nil {
                            let index = player.pieces.indexOf(piece!)////extension
                            if index != nil {
                                momentoPieceRemovedPlayer = player
                                player.pieces.removeAtIndex(index!)
                            }
                        }
                    }
                    
                    // update position and save momento
                    let momentoPosition = selectedPiece!.position
                    selectedPiece!.position = position

                    // if turn conditions are met, update the view, else restore momento
                    if turnConditionsAreMet(turnConditions) {
                        // update the view and complete the turn
                        print("legal move")
                        
                        // update view, remove pieceView if needed
                        if momentoPieceRemoved != nil {
                            if let match = pieceViews.elementPassing({$0.tag == momentoPieceRemoved!.tag}) {
                                match.removeFromSuperview()
                            }
                        }
                        
                        // update view, animate into position
                        animatePiece(selectedPiece!, position: selectedPiece!.position)
                        
                        // check for gameOver
                        if gameIsOver() {
                            statusDelegate?.gameMessage(players[whoseTurn].orientation.colorString() + " Won!!!", status: .GameOver)

                        }
                        
                        
                        // move the piece into new position, or listen to position change and change position
                        
                        selectedPiece!.selected = false
                        selectedPiece = nil
                        whoseTurn += 1
                        statusDelegate?.gameMessage(players[whoseTurn].orientation.colorString() + "'s turn", status: .WhoseTurn)


                        
                    } else {
                        // restore momento - marked as first move
                        if momentoMarkedFirstMove {
                            selectedPiece!.isFirstMove = true
                        }
                        
                        // restore momento - return removed piece
                        if momentoPieceRemoved != nil && momentoPieceRemovedPlayer != nil {
                            momentoPieceRemovedPlayer!.pieces.append(momentoPieceRemoved!)
                        }
                        
                        // restore momento - return moved piece
                        selectedPiece!.position = momentoPosition
                        
                        // delesect
                        selectedPiece!.selected = false
                        selectedPiece = nil
                    }
                } else {
                    // delesect, the move isn't legal
                    selectedPiece!.selected = false
                    selectedPiece = nil
                }
            }
        }
    }
    
    func gameIsOver() -> Bool {
        var gameOver = false
        for player in players where gameOver == false{
            if !player.pieces.contains({$0.name == "King"}) {
                gameOver = true
            }
            
        }
        return gameOver
    }
    
    func positionFromTranslation(translation: Position, fromPosition: Position, orientation: PlayerOrientation) -> Position {
        switch orientation {
        case .top:
            let row = fromPosition.row + translation.row
            let column = fromPosition.column + translation.column
            return Position(row: row, column: column)
        case .bottom:
            let row = fromPosition.row - translation.row
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
            
            // animate the change
            boardView.setNeedsUpdateConstraints()
            UIView.animateWithDuration(0.5) {
                self.boardView.layoutIfNeeded()
            }
        }
    }
}
