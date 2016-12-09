//
//  Board.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


/// Position Class: rows and columns, equatable

class Position: NSObject {
    var row: Int
    var column: Int
    
    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
    
    class func positionFromTranslation(_ translation: Translation, fromPosition: Position, direction: Direction) -> Position {
        let row: Int
        let column: Int
        switch direction {
        case .bottom:
            row = fromPosition.row + translation.row
            column = fromPosition.column - translation.column
        case .top:
            row = fromPosition.row - translation.row
            column = fromPosition.column + translation.column
        case .left:
            row = fromPosition.row - translation.column
            column = fromPosition.column - translation.row
        case .right:
            row = fromPosition.row + translation.column
            column = fromPosition.column + translation.row
        }
        return Position(row: row, column: column)
    }
    
    class func calculateTranslation(fromPosition:Position, toPosition: Position, direction: Direction) -> Translation {
        let row: Int
        let column: Int
        switch direction {
        case .bottom:
            row = toPosition.row - fromPosition.row
            column = fromPosition.column - toPosition.column
        case .top:
            row = fromPosition.row - toPosition.row
            column = toPosition.column - fromPosition.column
        case .left:
            row = fromPosition.column - toPosition.column
            column = fromPosition.row - toPosition.row
        case .right:
            row = toPosition.column - fromPosition.column
            column = toPosition.row - fromPosition.row
        }
        return Translation(row: row, column: column)
    }
}

func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.row == rhs.row && lhs.column == rhs.column
}

typealias Translation = Position



/// Board Class: Grid of rows and columns that may include empty cells.

class Board {
    var numRows: Int
    var numColumns: Int
    var numCells: Int {get {return numRows * numColumns}}
    var emptyCells: Set<Int>?
    var indexesNotEmpty: Set<Int> {
        get {
            return Set(0..<numCells).subtracting(emptyCells ?? [])
        }
    }
    
    convenience init() {
        self.init(numRows: 5, numColumns: 5)
    }
    
    init(numRows: Int, numColumns: Int, emptyCells: Set<Int>? = nil) {
        self.numRows = numRows
        self.numColumns = numColumns
        self.emptyCells = emptyCells
    }
    
    func index(position: Position) -> Int {
        return position.column + position.row * numColumns
    }
    
    func position(index: Int) -> Position {
        if numColumns > 0  {
            return Position(row: index / numColumns, column: index % numColumns)
        } else {
            return Position(row: 0, column: 0)
        }
    }
    
    func isACellAndIsNotEmpty(index: Int) -> Bool {
        return indexesNotEmpty.contains(index)
    }
    
    func copy() -> Board {
        return Board(numRows: numRows, numColumns: numColumns, emptyCells: emptyCells)
    }
}


/// makes a checkered view from a Board. checkered will offset images by 1 on the next row. empty cells are clear placeholder views

class BoardView: UIView {
    var cells = [UIView]()
    let images: [UIImage]?
    let backgroundColors: [UIColor]?
    var checkered = true

    init() {
        images = nil
        self.backgroundColors = nil
        super.init(frame: CGRect.zero)
    }
    
    init (board: Board, checkered: Bool, images: [UIImage]?, backgroundColors: [UIColor]?) {
        self.checkered = checkered
        self.images = images
        self.backgroundColors = backgroundColors
        super.init(frame: CGRect.zero)
        makeCells(board: board)
    }
    
    func makeCells(board: Board) {
        var imageIndex = 0 {
            didSet {if imageIndex >= images?.count {imageIndex = 0}}
        }
        var colorIndex = 0 {
            didSet {if colorIndex >= backgroundColors?.count {colorIndex = 0}}
        }
        
        for i in 0..<board.numCells {
            
            // make a cell
            let cell = UIView()
            cell.tag = i
            
            // set the image or color
            let evenNumberColumns = board.numColumns % 2 == 0
            if checkered && evenNumberColumns{
                let inFirstColumn = board.position(index: i).column == 0
                if inFirstColumn {
                    let onOddRow = board.position(index: i).row % 2 != 0
                    if onOddRow {
                        imageIndex = 1
                        colorIndex = 1
                    }
                    else {
                        imageIndex = 0
                        colorIndex = 0
                    }
                }
            }
            
            if let empty = board.emptyCells, empty.contains(i) {
                cell.backgroundColor = UIColor.clear
            } else {
                if imageIndex < images?.count {
                    let imageView = UIImageView(image: images![imageIndex])
                    cell.addSubview(imageView)
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate(NSLayoutConstraint.bindTopBottomLeftRight(imageView))
                }
                if colorIndex < backgroundColors?.count {
                    cell.backgroundColor = backgroundColors![colorIndex]
                }
            }
            imageIndex += 1
            colorIndex += 1
            
            // add to array
            cells.append(cell)
            self.addSubview(cell)
            cell.translatesAutoresizingMaskIntoConstraints = false
        }
        let constraints = NSLayoutConstraint.constraintsForGrid(views: cells, width: board.numColumns)
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



// compare nil values

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}









