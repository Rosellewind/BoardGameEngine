//
//  RulesVC.swift
//  Chess
//
//  Created by Roselle Tanner on 2/8/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import UIKit

class RulesVC: UIViewController {
    
    @IBOutlet weak var rulesImageView: UIImageView!
    var gameVariation: GameVariation = ChessVariation.standardChess

    override func viewDidLoad() {
        super.viewDidLoad()
        if let chessVariation = gameVariation as? ChessVariation {
            switch chessVariation {
            case .standardChess, .fourPlayer, .fourPlayerX:
                rulesImageView.image = UIImage(named: "BasicChessRules")
            }
        }
        if let uniqueVariation = gameVariation as? UniqueVariation {
            switch uniqueVariation {
            case .blackHole:
                rulesImageView.image = UIImage(named: "BlackHoleRules")
            case .galaxy:
                rulesImageView.image = UIImage(named: "GalaxyGameRules")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
