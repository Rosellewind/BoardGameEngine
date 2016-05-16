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

class Board {///// call model?
    let numRows: Int
    let numColumns: Int
    let numCells: Int
    let skipCells: [Int]?
    
    init(numRows: Int, numColumns: Int, skipCells: [Int]?) {
        self.numRows = numRows
        self.numColumns = numColumns
        self.numCells = numRows * numColumns
        self.skipCells = skipCells
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
    let colors: [UIColor]
    
    init (board: Board, colors: [UIColor]) {
        self.colors = colors
        super.init(frame: CGRectZero)
        
        // make cells
        var colorIndex = 0 {
            didSet {
                if colorIndex == colors.count {
                    colorIndex = 0
                }
            }
        }
        for i in 0..<board.numCells {
            
            // make a cell
            let cell = UIView()
            cell.tag = i
            
            // set the color
            if colors.count > 0 && !(board.skipCells?.contains(i))! {
                if let skips = board.skipCells where skips.contains(i) {
                    cell.backgroundColor = UIColor.clearColor()
                } else {
                    cell.backgroundColor = colors[colorIndex]
                }
            }
            colorIndex += 1

            // add to array
            cells.append(cell)
            cell.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(cell)
        }
        
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