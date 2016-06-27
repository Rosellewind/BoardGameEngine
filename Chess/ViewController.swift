//
//  ViewController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GameProtocol {
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var game: Game!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        setupGame()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupGame() {
        game = ChessGame(variation: .StandardChess, gameView: gameView)
        game.statusDelegate = self
        game = Game(gameView: gameView)
    }
    
    func gameMessage(string: String, status: GameStatus?) {
        self.topLabel.text = string
        switch status ?? .Default {
        case .GameOver:
            //show restart button
            setupGame()////temp
            break
        default:
            break
        }
    }



}

