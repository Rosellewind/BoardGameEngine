//
//  ViewController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var gameView: UIView!
    
    var gameController: GameController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        gameController = GameController(variation: .StandardChess, gameView: gameView)
//        gameController = GameController(variation: .Galaxy, gameView: gameView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

