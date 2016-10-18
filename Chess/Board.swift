//
//  Board.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit
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



class Position: NSObject {
    var row: Int
    var column: Int
    
    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}
func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.row == rhs.row && lhs.column == rhs.column
}

typealias Translation = Position



/// Grid of rows and columns. numCells is calculated. skipped cells are empty at indicated index

class Board {
    var numRows: Int
    var numColumns: Int
    var numCells: Int {get {return numRows * numColumns}}
    let skipCells: Set<Int>?
    var indexes = Set<Int>()
    
    convenience init() {
        self.init(numRows: 5, numColumns: 5)
    }
    
    init(numRows: Int, numColumns: Int, skipCells: Set<Int>? = nil) {
        self.numRows = numRows
        self.numColumns = numColumns
        self.skipCells = skipCells
        var temp = [Int]()
        temp += 0..<numCells
        indexes = Set(temp)
        if let skip = skipCells {
            indexes = indexes.subtracting(skip)
        }
    }
    
    deinit {
        print("deinit Board")
    }
    
    func index(_ position: Position) -> Int {
        return position.column + position.row * numColumns
    }
    
    func position(_ index: Int) -> Position {
        if numColumns > 0  {
            return Position(row: index / numColumns, column: index % numColumns)
        } else {
            return Position(row: 0, column: 0)
        }
    }
    
    func isCell(index: Int) -> Bool {
        return indexes.contains(index)
    }
    
    func copy() -> Board {
        return Board(numRows: numRows, numColumns: numColumns, skipCells: skipCells)
    }
}


/// makes a checkered view from a Board. checkered will offset images by 1 on the next row. skipped cells are clear placeholder views

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
        makeCells(board)
    }
    
    deinit {
        print("deinit BoardView")
    }
    
    func makeCells(_ board: Board) {
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
                let inFirstColumn = board.position(i).column == 0
                if inFirstColumn {
                    let onOddRow = board.position(i).row % 2 != 0
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
            
            if let skips = board.skipCells , skips.contains(i) {
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
        addConstraintsToCells(board)
    }
    
    func addConstraintsToCells(_ board: Board) {
        
        //autolayout cells
        var constraints = [NSLayoutConstraint]()
        
        // add horizontal constraints
        for i in stride(from: 0, to: board.numCells, by: board.numColumns) {
            let range = i..<i + board.numColumns
            let slice: Array<UIView> = Array(cells[range])
            let horizontal = NSLayoutConstraint.bindHorizontally(slice)
            constraints.append(contentsOf: horizontal)
            let widths = NSLayoutConstraint.equalWidths(slice)
            constraints.append(contentsOf: widths)
        }
        
        // add vertical constraints
        for i in 0..<board.numColumns {
            var verticalCells = [UIView]()
            for j in stride(from: i, to: board.numCells, by: board.numColumns)  {
                verticalCells.append(cells[j])
            }
            let vertical = NSLayoutConstraint.bindVertically(verticalCells)
            constraints.append(contentsOf: vertical)
            let heights = NSLayoutConstraint.equalHeights(verticalCells)
            constraints.append(contentsOf: heights)
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}












