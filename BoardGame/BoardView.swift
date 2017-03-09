//
//  File.swift
//  Chess
//
//  Created by Roselle Tanner on 3/8/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import UIKit

class BoardView: UIView {
    var cells = [Cell]()
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
            let position = board.position(index: i)
            let cell = Cell(position: position)
            cell.tag = i
            
            // accessibility
            cell.positionDescription = board.numberedDescription(position: position)
            
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
            
            if let skipped = board.skipCells, skipped.contains(i) {
                cell.isHidden = true
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
