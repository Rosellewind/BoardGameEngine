//
//  Game.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

//// castling, en passant, pawn promotion, check/mate
//// further the momento pattern
//  checkmate the opponent; this occurs when the opponent's king is in check, and there is no legal way to remove it from attack. It is illegal for a player to make a move that would put or leave his own king in check.
//// stopped here **** castling is not done, need completionblock, move()


import UIKit



protocol GameProtocol {
    func gameMessage(string: String, status: GameStatus?)
}


enum GameStatus {
    case GameOver, WhoseTurn, IllegalMove, Default
}

class Game {
    var board: Board
    var boardView: BoardView
    var players: [Player]
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
    var statusDelegate: GameProtocol? {
        didSet {
            statusDelegate?.gameMessage(players[whoseTurn].name ?? "" + " Starts!", status: .WhoseTurn)
        }
    }
    
    init(gameView: UIView) {
        // create the board
        board = Board(numRows: 8, numColumns: 5, skipCells: [0, 4, 20])
        
        // create the boardView
        var images = [UIImage]()
        for i in 1...3 {
            if let image = UIImage(named: "\(i).jpg") {
                images.append(image)
            }
        }
        boardView = BoardView(board: board, checkered: false, images: images, backgroundColors: nil)
        
        // add the view
        gameView.addSubview(boardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(boardView))
        
        // create the players with pieces
        players = [Player(name: "alien", index: 0, forwardDirection: .top, pieces: [Piece(name: "hi", position: Position(row: 0,column: 0), isLegalMove: {_ in return (true, nil)})])]
        
        // create pieceView's
        for player in players {
            for piece in player.pieces {
                if let image = UIImage(named: piece.name + (player.name ?? "")) {
                    let pieceView = PieceView(image: image)
                    pieceView.tag = piece.tag
                    pieceView.observing = [(piece, "selected")]
                    pieceViews.append(pieceView)
                    
                    let indexOfPieceOnBoard = board.index(piece.position)
                    if let cell = boardView.cells.elementPassing({return indexOfPieceOnBoard == $0.tag}) {
                        boardView.addSubview(pieceView)
                        pieceView.constrainToCell(cell)
                    }
                }
            }
        }
        
        // add taps to cells on boardView
        boardView.cells.forEach({ (view: UIView) in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Game.cellTapped(_:))))
        })
    }
    
    func pieceConditionsAreMet(piece: Piece, player: Player, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?) -> Bool {
        var conditionsAreMet = true
        for condition in conditions ?? [] where conditionsAreMet == true {
            switch condition.condition {
            case .CantBeOccupied:
                for translation in condition.positions ?? [] {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying != nil {
                        conditionsAreMet = false
                    }
                }
                ///pos to trans
                
            case .MustBeOccupied:
                for translation in condition.positions ?? [] {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying == nil {
                        conditionsAreMet = false
                    }
                }
            case .MustBeOccupiedByOpponent:
                for translation in condition.positions ?? [] {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying == nil {
                        conditionsAreMet = false
                    } else if player.pieces.contains(pieceOccupying!) {
                        conditionsAreMet = false
                    }
                }
            case .CantBeOccupiedBySelf:
                for translation in condition.positions ?? [] {
                    let positionToCheck = positionFromTranslation(translation, fromPosition: piece.position, direction: player.forwardDirection)
                    let pieceOccupying = pieceForPosition(positionToCheck)
                    if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                        conditionsAreMet = false
                    }
                }
            case .IsInitialMove:
                if !piece.isFirstMove {
                    conditionsAreMet = false
                }
            case .RookCanCastle://///king?////test
                let rooks = player.pieces.filter({$0.name.hasPrefix("Rook")})
                var castlingRook: Piece?
                var rookLandingSpot: Position
                if let king = player.pieces.elementPassing({$0.name == "King"}) {
                    for rook in rooks where castlingRook == nil {
                        if rook.isFirstMove {
                            for translation in condition.positions ?? []  where castlingRook == nil  {
                                let position = positionFromTranslation(translation, fromPosition: king.position, direction: player.forwardDirection)
                                let translation = calculateTranslation(rook.position, toPosition: position, direction: player.forwardDirection)
                                let moveFunction = rook.isLegalMove(translation: translation)
                                if pieceConditionsAreMet(rook, player: player, conditions: moveFunction.conditions) {
                                    castlingRook = rook
                                    let rookOffset = position.column < rook.position.column ? -1 : 1
                                    rookLandingSpot = Position(row: position.row, column: position.column + rookOffset)
                                }
                            }
                        }
                    }
                }
                if castlingRook != nil {
                    ////****move rook to rookLandingSpot
//                    let completionBlock = move(rook, rookLandingSpot)
                } else {
                    conditionsAreMet = false
                }
            case .CantBeInCheckDuring:////test
                ////temp
                if isCheck(player) {
                    conditionsAreMet = false
                }
                
                
//                for translation in condition.positions {
//                    
//                }
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
                        let translation = calculateTranslation(piece.position, toPosition: king.position, direction: players[nextTurn].forwardDirection)
                        let moveFunction = piece.isLegalMove(translation: translation)
                        if moveFunction.isLegal && pieceConditionsAreMet(piece, player: players[nextTurn], conditions: moveFunction.conditions){
                            conditionsAreMet = false
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
                let translation = calculateTranslation(selectedPiece!.position, toPosition: position, direction: players[whoseTurn].forwardDirection)
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
                        for player in players {
                            isCheck(player)
                            if isCheckMate(player) {
                                statusDelegate?.gameMessage(player.name ?? "" + " Is In Checkmate!!!", status: .GameOver)
                            }
                        }
                        
                        
                        // move the piece into new position, or listen to position change and change position
                        
                        selectedPiece!.selected = false
                        selectedPiece = nil
                        whoseTurn += 1
                        statusDelegate?.gameMessage(players[whoseTurn].name ?? "" + "'s turn", status: .WhoseTurn)


                        
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
    
    func isCheck(player: Player) -> Bool {
        // all other players pieces can not take king
        var isCheck = false
        if let king = player.pieces.elementPassing({$0.name == "King"}) {
            for otherPlayer in players where isCheck == false {
                if otherPlayer === player {
                    continue
                } else {
                    for piece in otherPlayer.pieces where isCheck == false {
                        let translation = calculateTranslation(piece.position, toPosition: king.position, direction: otherPlayer.forwardDirection)
                        let moveFunction = piece.isLegalMove(translation: translation)
                        isCheck = moveFunction.isLegal && pieceConditionsAreMet(piece, player: otherPlayer, conditions: moveFunction.conditions)
                    }
                }
            }
        }
        print("\(player.name) is in Check: \(isCheck)")
        return isCheck
    }
    
    func isCheckMate(player: Player) -> Bool {
        var isCheckMate = true
        let otherPlayers = players.filter({$0 !== player})
        if let king = player.pieces.elementPassing({$0.name == "King"}) {
            var positionsToCheck = [Position(row: king.position.row - 1, column: king.position.column - 1),
                                    Position(row: king.position.row - 1, column: king.position.column),
                                    Position(row: king.position.row - 1, column: king.position.column + 1),
                                    Position(row: king.position.row, column: king.position.column - 1),
                                    Position(row: king.position.row, column: king.position.column),
                                    Position(row: king.position.row, column: king.position.column + 1),
                                    Position(row: king.position.row + 1, column: king.position.column - 1),
                                    Position(row: king.position.row + 1, column: king.position.column),
                                    Position(row: king.position.row + 1, column: king.position.column + 1)]
            // trim positions that are off the board
            positionsToCheck = positionsToCheck.filter({$0.row >= 0 && $0.row < board.numRows})
            
            // trim positions that are already occupied   ////castling/otherrules?
            positionsToCheck = positionsToCheck.filter({pieceForPosition($0) == nil})
            if positionsToCheck.count > 0 {
                for position in positionsToCheck where isCheckMate == true {
                    var positionIsSafe = true
                    for otherPlayer in otherPlayers where positionIsSafe == true {
                        for piece in otherPlayer.pieces where positionIsSafe == true {
                            let translation = calculateTranslation(piece.position, toPosition: position, direction: otherPlayer.forwardDirection)
                            let moveFunction = piece.isLegalMove(translation: translation)
                            positionIsSafe = !(moveFunction.isLegal && pieceConditionsAreMet(piece, player: otherPlayer, conditions: moveFunction.conditions))
                        }
                    }
                    if positionIsSafe {
                        isCheckMate = false
                    }
                }
            } else {
                isCheckMate = false
            }

        }
        print("\(player.name) is in checkmate: \(isCheckMate)")

        return isCheckMate
    }
    
    func positionFromTranslation(translation: Position, fromPosition: Position, direction: Direction) -> Position {
        switch direction {
        case .bottom:
            let row = fromPosition.row + translation.row
            let column = fromPosition.column + translation.column
            return Position(row: row, column: column)
        case .top:
            let row = fromPosition.row - translation.row
            let column = fromPosition.column + translation.column
            return Position(row: row, column: column)
        default:
            return Position(row: 0, column: 0) //// implement others later
        }
    }
    
    func calculateTranslation(fromPosition:Position, toPosition: Position, direction: Direction) -> Position {
        
        switch direction {
        case .bottom:
            let row = toPosition.row - fromPosition.row
            let column = toPosition.column - fromPosition.column
            return Position(row: row, column: column)
        case .top:
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
