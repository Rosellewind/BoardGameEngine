//
//  ViewController.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GamePresenterProtocol {
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var game: Game!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupGame()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupGame() {
        game = ChessGame(chessVariation: .standardChess, gameView: gameView)
        game.presenterDelegate = self
//        game = Game(gameView: gameView)
    }
    
    func gameMessage(_ string: String, status: GameStatus?) {
        self.topLabel.text = string
        switch status ?? .default {
        case .gameOver:
            //show restart button
            setupGame()////temp
            break
        default:
            break
        }
    }

    func showAlert(_ alert: UIViewController) {
        self.present(alert, animated: true, completion: nil)
    }

}

