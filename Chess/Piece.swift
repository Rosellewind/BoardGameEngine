//
//  Piece.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//


import UIKit


protocol PiecesCreator {
    func makePieces(variation: Int, playerId: Int) -> [Piece]
}

enum LegalIfCondition {
    case MustBeOccupied, CantBeOccupied, MustBeOccupiedByOpponent, CantBeOccupiedBySelf, IsInitialMove, RookCanCastle, CantBeInCheckDuring
}

class Piece: NSObject, NSCopying {
    var name: String
    var tag = 0
    var position: Position
    let startingPosition: Position
    var isLegalMove: (translation: Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?)
    var isFirstMove = true
    dynamic var selected = false
    
    init(name: String, position: Position, isLegalMove: (Position) -> (isLegal: Bool, conditions: [(condition: LegalIfCondition, positions: [Position]?)]?)) {
        self.name = name
        self.position = position
        self.startingPosition = position
        self.isLegalMove = isLegalMove
    }
    
    required init(toCopy: Piece) {
        self.name = toCopy.name
        self.tag = toCopy.tag
        self.position = toCopy.position
        self.startingPosition = toCopy.position
        self.isLegalMove = toCopy.isLegalMove
        self.isFirstMove = toCopy.isFirstMove
        self.selected = toCopy.selected
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.init(toCopy: self)
    }
}


private var myContext = 0

class PieceView: UIView {
    var image: UIImage
    var positionConstraints = [NSLayoutConstraint]()
    
    var observing: [(objectToObserve: NSObject, keyPath: String)]? {
        willSet {
            for observe in observing ?? [] {
                observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
            }
        }
        didSet {
            for observe in observing ?? [] {
                observe.objectToObserve.addObserver(self, forKeyPath: observe.keyPath, options: .New, context: &myContext)
            }
        }
    }

    init(image: UIImage, pieceTag: Int) {
        self.image = image
        super.init(frame: CGRectZero)
        self.tag = pieceTag
        self.userInteractionEnabled = false
        
        // add imageView as subview
        let imageView = UIImageView(image:image)
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.bindTopBottomLeftRight(imageView))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if keyPath == "selected" {
                if let piece = object as? Piece {
                    if piece.selected == true {
                        self.alpha = 0.4
                    } else {
                        self.alpha = 1.0
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        observing = nil
    }
    
    func constrainToCell(cell: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: cell, attribute: .Width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: cell, attribute: .Height, multiplier: 1, constant: 0)
        let positionX = NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: cell, attribute: .CenterX, multiplier: 1, constant: 0)
        let positionY = NSLayoutConstraint(item: self, attribute: .CenterY, relatedBy: .Equal, toItem: cell, attribute: .CenterY, multiplier: 1, constant: 0)
        positionConstraints = [positionX, positionY]
        NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, positionX, positionY])
    }
}
