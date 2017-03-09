//
//  PieceView.swift
//  Chess
//
//  Created by Roselle Tanner on 3/8/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import UIKit

class PieceView: UIImageView {
    var positionConstraints = [NSLayoutConstraint]()
    
    init(image: UIImage, pieceTag: Int) {
        super.init(image:image)
        self.tag = pieceTag
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func constrainToCell(_ cell: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: cell, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: cell, attribute: .height, multiplier: 1, constant: 0)
        let positionX = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: cell, attribute: .centerX, multiplier: 1, constant: 0)
        let positionY = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0)
        positionConstraints = [positionX, positionY]
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, positionX, positionY])
    }
}
