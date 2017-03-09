//
//  RulesVC.swift
//  Chess
//
//  Created by Roselle Tanner on 2/8/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import UIKit

class RulesVC: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var rulesImageView: UIImageView!
    var gameVariation: GameVariation = ChessVariation.standardChess

    override func viewDidLoad() {
        
        super.viewDidLoad()
        let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        let url: URL?
        if let chessVariation = gameVariation as? ChessVariation {
            switch chessVariation {
            case .standardChess, .fourPlayer, .fourPlayerX:
                url = Bundle.main.url(forResource: "ChessRules", withExtension: "html")
            }
        } else if let uniqueVariation = gameVariation as? UniqueVariation {
            switch uniqueVariation {
            case .blackHole:
                url = Bundle.main.url(forResource: "BlackHoleRules", withExtension: "html")
            case .galaxy:
                url = Bundle.main.url(forResource: "GalaxyGameRules", withExtension: "html")

            }
        } else {
            url = nil
        }
        
        if url != nil {
            webView.loadRequest(NSURLRequest(url: url!) as URLRequest)
        }
        
        self.view.addSubview(webView)
    }
    


}
