//
//  GamePlayVC.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//
// TODO: end of game?

import UIKit

class GamePlayVC: UIViewController, GamePresenterProtocol {
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var gameVariation: GameVariation = ChessVariation.standardChess
    var game: GameVC!
    
    override func viewDidAppear(_ animated: Bool) {
        setupGame()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(confirmBack(sender:)))
        
        // allow for accessibility resize text
        self.topLabel.font = UIFont.preferredFont(forTextStyle: .body)
        self.bottomLabel.font = UIFont.preferredFont(forTextStyle: .body)
        if #available(iOS 10.0, *) {    // allows resizing midstream, otherwise need UI redraw
            self.topLabel.adjustsFontForContentSizeCategory =  true
            self.bottomLabel.adjustsFontForContentSizeCategory =  true
        }
    }
    
    func setupGame() {
        for subview in gameView.subviews {
            subview.removeFromSuperview()
        }
        
        if gameVariation is UniqueVariation {
            game = GameVC(gameVariation: gameVariation as! UniqueVariation, gameView: gameView)
        } else if gameVariation is ChessVariation {
            game = ChessGameVC(chessVariation: gameVariation as! ChessVariation, gameView: gameView)
        } else {
            game = ChessGameVC(chessVariation: .standardChess, gameView: gameView)
        }
        
        game.presenterDelegate = self
    }
    
    func confirmBack(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Back to the Menu", message: "Do you want to erase your game and go back to the menu?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .destructive, handler: { (UIAlertAction) -> Void in
            if let navController = self.navigationController {
                navController.popViewController(animated: true)
            }
            return
        })
        alert.addAction(yes)
        let no = UIAlertAction(title: "NO", style: .default, handler: nil)
        alert.addAction(no)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RulesVC {
            vc.gameVariation = gameVariation
        }
    }

}


// GamePresenterProtocol

extension GamePlayVC {
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



