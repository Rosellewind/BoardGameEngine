//
//  Board.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

struct Position {
    var row: Int
    var column: Int
    
    
}

class Board {
    let numRows: Int
    let numColumns: Int
    let numCells: Int
    let skipCells: [Int]?
    let checkered: Bool
    
    init(numRows: Int, numColumns: Int, skipCells: [Int]?, checkered: Bool) {
        self.numRows = numRows
        self.numColumns = numColumns
        self.numCells = numRows * numColumns
        self.skipCells = skipCells
        self.checkered = checkered
    }
    
    func index(position: Position) -> Int {
        return position.column + position.row * numColumns
    }
    
    func position(index: Int) -> Position {//0
        return Position(row: index / numColumns, column: index % numColumns)
    }
}

class BoardView: UIView {
    var cells = [UIView]()
    let images: [UIImage]?
    let colors: [UIColor]?
    
    
    init (board: Board, images: [UIImage]?, colors: [UIColor]?) {
        self.images = images
        self.colors = colors
        super.init(frame: CGRectZero)
        makeCells(board)
        
              }
    func makeCells(board: Board) {
        var imageIndex = 0 {
            didSet {if imageIndex >= images?.count {imageIndex = 0}}
        }
        var colorIndex = 0 {
            didSet {if colorIndex >= colors?.count {colorIndex = 0}}
        }
        
        for i in 0..<board.numCells {
            
            // make a cell
            let cell = UIView()
            cell.tag = i
            
            // set the image or color
            let evenNumberColumns = board.numColumns % 2 == 0
            if board.checkered && evenNumberColumns{
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
            
            if let skips = board.skipCells where skips.contains(i) {
                cell.backgroundColor = UIColor.clearColor()
            } else {
                if imageIndex < images?.count {
                    let imageView = UIImageView(image: images![imageIndex])
                    cell.addSubview(imageView)
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(imageView))
                }
                if colorIndex < colors?.count {
                    cell.backgroundColor = colors![colorIndex]
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
    
    func addConstraintsToCells(board: Board) {
        //autolayout cells
        var constraints = [NSLayoutConstraint]()
        
        // add horizontal constraints
        for i in 0.stride(to: board.numCells, by: board.numColumns) {
            let range = i..<i + board.numColumns
            let slice: Array<UIView> = Array(cells[range])
            let horizontal = NSLayoutConstraint.bindHorizontally(slice)
            constraints.appendContentsOf(horizontal)
            let widths = NSLayoutConstraint.equalWidths(slice)
            constraints.appendContentsOf(widths)
        }
        
        // add vertical constraints
        for i in 0..<board.numColumns {
            var verticalCells = [UIView]()
            for j in i.stride(to: board.numCells, by: board.numColumns)  {
                verticalCells.append(cells[j])
            }
            let vertical = NSLayoutConstraint.bindVertically(verticalCells)
            constraints.appendContentsOf(vertical)
            let heights = NSLayoutConstraint.equalHeights(verticalCells)
            constraints.appendContentsOf(heights)
        }
        NSLayoutConstraint.activateConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}












