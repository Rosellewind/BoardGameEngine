//
//  Game.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

//// cantbeincheckduring, en passant, pawn promotion, check/mate



import UIKit



protocol GamePresenterProtocol {
    func gameMessage(_ string: String, status: GameStatus?)
    func showAlert(_ alert: UIViewController)
}

enum GameStatus {
    case gameOver, whoseTurn, illegalMove, `default`
}

enum TurnCondition: Int {   // subclasses may add their own
    case none
}

class GameSnapshot {
    var board: Board
    var players: [Player]
    var selectedPiece: Piece?
    var whoseTurn: Int
    var nextTurn: Int
    var allPieces: [Piece] {
        get {
            var pieces = [Piece]()
            for player in players {
                pieces += player.pieces
            }
            return pieces
        }
    }
    convenience init(game: Game) {
        self.init(board: game.board, players: game.players, selectedPiece: game.selectedPiece, whoseTurn: game.whoseTurn, nextTurn: game.nextTurn)
    }
    init(board: Board, players: [Player], selectedPiece: Piece?, whoseTurn: Int, nextTurn: Int) {
        self.board = board.copy()
        self.players = players.map({$0.copy()})
        self.whoseTurn = whoseTurn
        self.nextTurn = nextTurn
        self.selectedPiece = self.allPieces.elementPassing({$0.id == selectedPiece?.id})
    }
    
    func copy() -> GameSnapshot {
        return GameSnapshot(board: board.copy(), players: players.map({$0.copy()}), selectedPiece: allPieces.elementPassing({$0.id == selectedPiece?.id}), whoseTurn: whoseTurn, nextTurn: nextTurn)
    }
}


class Game: PieceViewProtocol {
    var board: Board
    var boardView: BoardView
    var players: [Player]
    var pieceViews: [PieceView]
    var selectedPiece: Piece?
    var turnConditions: [TurnCondition.RawValue]?
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
    var presenterDelegate: GamePresenterProtocol? {
        didSet {
            presenterDelegate?.gameMessage((players[whoseTurn].name ?? "") + " Starts!", status: .whoseTurn)
        }
    }
    var allPieces: [Piece] {
        get {
            var pieces = [Piece]()
            for player in players {
                pieces += player.pieces
            }
            return pieces
        }
    }
    var reusableGameSnapshot: GameSnapshot?

    init(gameView: UIView, board: Board, boardView: BoardView, players: [Player], pieceViews: [PieceView]) {
        self.board = board
        self.boardView = boardView
        self.players = players
        self.pieceViews = pieceViews
        
        // boardView layout
        gameView.addSubview(boardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(NSLayoutConstraint.bindTopBottomLeftRight(boardView))
        
        // pieceView layout and observing
        pieceViews.forEach { (pieceView: PieceView) in
            if let piece = pieceForPieceView(pieceView) {
                // add delegate
                pieceView.delegate = self
                // add observing
                pieceView.observing = [(piece, "selected"), (piece, "position")]
                
                // pieceView layout
                let indexOfPieceOnBoard = board.index(piece.position)
                if let cell = boardView.cells.elementPassing({return indexOfPieceOnBoard == $0.tag}) {
                    boardView.addSubview(pieceView)
                    pieceView.constrainToCell(cell)
                }
            }
        }
        
        // add taps to cells on boardView
        boardView.cells.forEach({ (view: UIView) in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Game.cellTapped(_:))))
        })
        
        
    }
    
    /// creates a default board for testing purposes
    convenience init(gameView: UIView) {
        
        // create the board
        let defaultBoard = Board(numRows: 8, numColumns: 5, skipCells: [0, 4, 20])
        
        // create the boardView
        var images = [UIImage]()
        for i in 1...3 {
            if let image = UIImage(named: "\(i).jpg") {
                images.append(image)
            }
        }
        let defaultBoardView = BoardView(board: defaultBoard, checkered: false, images: images, backgroundColors: nil)
        
        // create the players with pieces
        let defaultPlayers = [Player(name: "alien", id: 0, forwardDirection: .top, pieces: [Piece(name: "hi", position: Position(row: 0,column: 0), isLegalMove: {_ in return (true, nil)})])]
        
        // create pieceView's
        var defaultPieceViews = [PieceView]()
        for player in defaultPlayers {
            for piece in player.pieces {
                if let image = UIImage(named: piece.name + (player.name ?? "")) {
                    let pieceView = PieceView(image: image, pieceTag: piece.id)
                    defaultPieceViews.append(pieceView)
                }
            }
        }
        self.init(gameView: gameView, board: defaultBoard, boardView: defaultBoardView, players: defaultPlayers, pieceViews: defaultPieceViews)
    }
    
    func pieceConditionsAreMet(_ piece: Piece, conditions: [(condition: Int, positions: [Position]?)]?, snapshot: GameSnapshot?) -> (isMet: Bool, completions: [(() -> Void)]?) {
        let pieceInSnapshot = snapshot?.allPieces.elementPassing({$0.id == piece.id})
        let thisPiece = pieceInSnapshot ?? piece
        
        var conditionsAreMet = true
        if let player = thisPiece.player {
            for condition in conditions ?? [] where conditionsAreMet == true {
                if let legalIfCondition = LegalIfCondition(rawValue:condition.condition) {
                    switch legalIfCondition {
                    case .cantBeOccupied:
                        for translation in condition.positions ?? [] {
                            let positionToCheck = positionFromTranslation(translation, fromPosition: thisPiece.position, direction: player.forwardDirection)
                            let pieceOccupying = pieceForPosition(positionToCheck, snapshot: snapshot)
                            if pieceOccupying != nil {
                                conditionsAreMet = false
                            }
                        }
                        ////pos to trans
                        
                    case .mustBeOccupied:
                        for translation in condition.positions ?? [] {
                            let positionToCheck = positionFromTranslation(translation, fromPosition: thisPiece.position, direction: player.forwardDirection)
                            let pieceOccupying = pieceForPosition(positionToCheck, snapshot: snapshot)
                            if pieceOccupying == nil {
                                conditionsAreMet = false
                            }
                        }
                    case .mustBeOccupiedByOpponent:
                        for translation in condition.positions ?? [] {
                            let positionToCheck = positionFromTranslation(translation, fromPosition: thisPiece.position, direction: player.forwardDirection)
                            let pieceOccupying = pieceForPosition(positionToCheck, snapshot: snapshot)
                            if pieceOccupying == nil {
                                conditionsAreMet = false
                            } else if player.pieces.contains(pieceOccupying!) {
                                conditionsAreMet = false
                            }
                        }
                    case .cantBeOccupiedBySelf:
                        for translation in condition.positions ?? [] {
                            let positionToCheck = positionFromTranslation(translation, fromPosition: thisPiece.position, direction: player.forwardDirection)
                            let pieceOccupying = pieceForPosition(positionToCheck, snapshot: snapshot)
                            if pieceOccupying != nil && player.pieces.contains(pieceOccupying!) {
                                conditionsAreMet = false
                            }
                        }
                    case .isInitialMove:
                        if !thisPiece.isFirstMove {
                            conditionsAreMet = false
                        }
                    }
                }
            }
        }
        return (conditionsAreMet, nil)
    }
    
    func turnConditionsAreMet(_ conditions: [TurnCondition.RawValue]?, snapshot: GameSnapshot?) -> Bool {
        for condition in conditions ?? [] {
            if let turnCondition = TurnCondition(rawValue: condition) { // implement later
                switch turnCondition {
                case .none:
                    return true
                }
            }
        }
        return true
    }
    
    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        if let view = sender.view {
            let positionTapped = board.position(view.tag)
            let pieceTapped = pieceForPosition(positionTapped, snapshot: nil)
            
            // beginning of turn, selecting the piece
            let isBeginningOfTurn = selectedPiece == nil
            if isBeginningOfTurn {
                // get the piece
                if pieceTapped != nil {// cell must be occupied for selection
                    let isPlayersOwnPiece = players[whoseTurn].pieces.contains(pieceTapped!)
                    if isPlayersOwnPiece {
                        pieceTapped!.selected = true
                        selectedPiece = pieceTapped
                    }
                }
            }
            
            // final part of turn, choosing where to go
            else {
                let translation = calculateTranslation(selectedPiece!.position, toPosition: positionTapped, direction: players[whoseTurn].forwardDirection)
                let moveFunction = selectedPiece!.isLegalMove(translation: translation)
                let pieceConditions = pieceConditionsAreMet(selectedPiece!, conditions: moveFunction.conditions, snapshot: nil)
                
                // check if move is legal and turn conditions are met
                if moveFunction.isLegal && pieceConditions.isMet {
                    
                    // create snapshot, check if turn conditions will be met
                    ///////////what if more than one move? implement
                    reusableGameSnapshot = GameSnapshot(game: self)
                    makeMoveInSnapshot(Move(piece: selectedPiece!, remove: false, position: positionTapped) , snapshot: reusableGameSnapshot!)
                    
                    if turnConditionsAreMet(turnConditions, snapshot: reusableGameSnapshot) {
                        
                        // remove occupying piece if needed
                        if selectedPiece!.removePieceOccupyingNewPosition == true && pieceTapped != nil {
                            makeMove(Move(piece: pieceTapped!, remove: true, position: nil))
                        }

                        // move the piece
                        makeMove(Move(piece: selectedPiece!, remove: false, position: positionTapped))
                        
                        // completions
                        if let completions = pieceConditions.completions {
                            for completion in completions {
                                completion()
                            }
                        }
                        
                        // check for gameOver
                        gameOver()
                        whoseTurn += 1
                        presenterDelegate?.gameMessage((players[whoseTurn].name ?? "") + "'s turn", status: .whoseTurn)
                        
                    }
                }
                selectedPiece!.selected = false
                selectedPiece = nil
            }
        }
    }
    
    func removePieceOccupyingPosition (_ position: Position) {
        
        
    }
    
    struct Move {
        let piece: Piece
        let remove: Bool
        let position: Position?
    }
    
    func makeMove(_ move: Move) {
        if move.remove {
            for player in players {
                if let index = player.pieces.index(of: move.piece) {
                    if let pieceViewToRemove = pieceViews.elementPassing({$0.tag == move.piece.id}) {
                        pieceViewToRemove.removeFromSuperview()
                    }
                    player.pieces.remove(at: index)
                }
            }
        } else if move.position != nil {
            move.piece.position = move.position!
        }
    }
    
    func makeMoves(_ moves: [Move]) {
        for move in moves {
            makeMove(move)
        }
    }
    
    func makeMoveInSnapshot(_ move: Move, snapshot: GameSnapshot) {
        if let snapshotPiece = snapshot.allPieces.elementPassing({$0.id == move.piece.id && $0.player != nil && $0.player!.id == move.piece.player!.id}) {
            if move.remove {
                for player in snapshot.players {
                    if let index = player.pieces.index(of: snapshotPiece) {
                        player.pieces.remove(at: index)
                    }
                }
            } else if move.position != nil {
                snapshotPiece.position = move.position!
            }
        }

    }
    
    func makeMovesInSnapshot(_ moves: [Move], snapshot: GameSnapshot) {
        for move in moves {
            makeMoveInSnapshot(move, snapshot: snapshot)
        }
    }
    
    var memento: (piece: Piece, isFirstMove: Bool, position: Position, pieceRemoved: Piece?, pieceRemovedPlayer: Player?)?
    
    func restoreMemento() {
        if let thisMemento = memento {
            thisMemento.piece.isFirstMove = thisMemento.isFirstMove
            thisMemento.piece.position = thisMemento.position
            if let pieceToRestore = thisMemento.pieceRemoved, let player = thisMemento.pieceRemovedPlayer {
                player.pieces.append(pieceToRestore)
            }
        }
    }
    
    func gameOver() -> Bool {
        for player in players {
            if player.pieces.count <= 0 {
                return true
            }
        }
        return false
    }
    

    
    func positionFromTranslation(_ translation: Position, fromPosition: Position, direction: Direction) -> Position {
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
    
    func calculateTranslation(_ fromPosition:Position, toPosition: Position, direction: Direction) -> Position {
        
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
    
    func pieceForPosition(_ position: Position, snapshot: GameSnapshot?) -> Piece? {
        let pieces = snapshot?.allPieces ?? allPieces
        var pieceFound: Piece?
        for piece in pieces {
            if piece.position == position {
                pieceFound = piece
            }
        }
        return pieceFound
    }
    
    func pieceForPieceView(_ pieceView: PieceView) -> Piece? {
        for piece in allPieces {
            if piece.id == pieceView.tag {return piece}
        }
        return nil
    }
    
//    func animatePiece(piece: Piece, position: Position) {
//        if let pieceView = pieceViews.elementPassing({$0.tag == piece.tag}) {
//            // deactivate position constraints
//            NSLayoutConstraint.deactivateConstraints(pieceView.positionConstraints)
//            
//            // activate new position constraints
//            let cellIndex = board.index(position)
//            let matchingCells = boardView.cells.filter({$0.tag == cellIndex})
//            if matchingCells.count > 0 {
//                let cell = matchingCells[0]
//                let positionX = NSLayoutConstraint(item: pieceView, attribute: .CenterX, relatedBy: .Equal, toItem: cell, attribute: .CenterX, multiplier: 1, constant: 0)
//                let positionY = NSLayoutConstraint(item: pieceView, attribute: .CenterY, relatedBy: .Equal, toItem: cell, attribute: .CenterY, multiplier: 1, constant: 0)
//                pieceView.positionConstraints = [positionX, positionY]
//                NSLayoutConstraint.activateConstraints(pieceView.positionConstraints)
//            }
//            
//            // animate the change
//            boardView.setNeedsUpdateConstraints()
//            UIView.animateWithDuration(0.5) {
//                self.boardView.layoutIfNeeded()
//            }
//        }
//    }
    func animateMove(_ pieceView: PieceView, position: Position, duration: TimeInterval) {
        
        // deactivate position constraints
        NSLayoutConstraint.deactivate(pieceView.positionConstraints)
        
        // activate new position constraints matching cell constraints
        let cellIndex = board.index(position)
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
}
