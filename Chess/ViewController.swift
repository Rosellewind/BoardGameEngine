//
//  ViewController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let board = Board(numRows: 6, numColumns: 5, skipCells: [0, 4, 11, 12])
    var boardView: BoardView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        boardView = BoardView(board: board, colors: [UIColor.redColor(), UIColor.blackColor()])
        if boardView != nil {
            self.view.addSubview(boardView!)
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(boardView!))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

