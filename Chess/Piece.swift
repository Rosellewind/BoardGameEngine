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

enum LegalIfCondition: Int {
    case MustBeOccupied, CantBeOccupied, MustBeOccupiedByOpponent, CantBeOccupiedBySelf, IsInitialMove
}

class Piece: NSObject, NSCopying {
    var name: String
    var id = 0
    var position: Position
    let startingPosition: Position
    var isLegalMove: (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?)
    var isFirstMove = true
    dynamic var selected = false
    weak var player: Player?
    
    init(name: String, position: Position, isLegalMove: (translation: Position) -> (isLegal: Bool, conditions: [(condition: Int, positions: [Position]?)]?)) {
        self.name = name
        self.position = position
        self.startingPosition = position
        self.isLegalMove = isLegalMove
    }
    
    required init(toCopy: Piece) {
        self.name = toCopy.name
        self.id = toCopy.id
        self.position = toCopy.position
        self.startingPosition = toCopy.position
        self.isLegalMove = toCopy.isLegalMove
        self.isFirstMove = toCopy.isFirstMove
        self.selected = toCopy.selected
        self.player = toCopy.player
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.init(toCopy: self)
    }
}


private var myContext = 0
protocol PieceViewProtocol {
    func animateMove(pieceView: PieceView, position: Position, duration: NSTimeInterval)
}

class PieceView: UIView {
    var image: UIImage
    var positionConstraints = [NSLayoutConstraint]()
    var delegate: PieceViewProtocol?
    var observing: [(objectToObserve: NSObject, keyPath: String)]? {
        willSet {
            for observe in observing ?? [] {
                observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
            }
        }
        didSet {
            for observe in observing ?? [] {
                observe.objectToObserve.addObserver(self, forKeyPath: observe.keyPath, options: [.New, .Old], context: &myContext)
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
//                if let theChange = change as? [String: Bool], new = theChange[NSKeyValueChangeNewKey] {
//                    if new == true {
//                        self.alpha = 0.4
//                    } else {
//                        self.alpha = 1.0
//                    }
//                }
                
                if let theChange = change as? [String: Bool] {
                    if let new = theChange[NSKeyValueChangeNewKey] {
                        if new == true {
                            self.alpha = 0.4
                        } else {
                            self.alpha = 1.0
                        }
                    }
                }
                
                
//                if let piece = object as? Piece {
//                    if piece.selected == true {
//                        self.alpha = 0.4
//                    } else {
//                        self.alpha = 1.0
//                    }
//                }
            } else if keyPath == "position" {
                if let theChange = change as? [String: Position] {
                    if let new = theChange[NSKeyValueChangeNewKey] {
                        if let old = theChange[NSKeyValueChangeOldKey] {
                            if new != old {
                                delegate?.animateMove(self, position: new, duration: 0.5)

                            }
                        }
                    }
                }
                
                
                
                if let piece = object as? Piece {///////////////////
                    delegate?.animateMove(self, position: piece.position, duration: 0.5)
                    
                    
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
