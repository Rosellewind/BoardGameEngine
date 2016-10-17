//
//  ChessVC.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit

class ChessVC: UIViewController, GamePresenterProtocol {
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
        for subview in gameView.subviews {
            subview.removeFromSuperview()
        }
        game = ChessGame(chessVariation: .standardChess, gameView: gameView)
        game.presenterDelegate = self
    }
    
    func gameMessage(_ string: String, status: GameStatus?) {
        self.topLabel.text = string
        switch status ?? .default {
        case .gameOver:
        
            //show restart button
            let alert = UIAlertController(title: "We have a winner!", message: string, preferredStyle: .alert)
            let okay = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                DispatchQueue.main.async {  // needed to prevent: _BSMachError: (os/kern) invalid capability (20), _BSMachError: (os/kern) invalid name (15)
                    self.setupGame()
                }
            })
            alert.addAction(okay)
            self.present(alert, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func secondaryGameMessage(string: String) {
        self.bottomLabel.text = string
    }

    func showAlert(_ alert: UIViewController) {
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)
    }

}

