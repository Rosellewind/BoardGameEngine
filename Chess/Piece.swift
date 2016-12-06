//
//  Piece.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//


import UIKit


protocol PiecesCreator {
    func makePieces(_ variation: Int, playerId: Int) -> [Piece]
}

enum LegalIfCondition: Int {
    case mustBeOccupied, mustBeVacantCell, mustBeOccupiedByOpponent, cantBeOccupiedBySelf, isInitialMove
}

typealias IsLegalMove = (_ : Translation) -> (isLegal: Bool, conditions: [(condition: Int, translations: [Translation]?)]?)

class Piece: NSObject, NSCopying {
    var name: String
    var id = 0
    dynamic var position: Position
        {
        didSet {
            self.isFirstMove = false
        }
    }
    var startingPosition: Position
    var isPossibleTranslation: (_ : Translation) -> Bool
    var isLegalMove: IsLegalMove
    var removePieceOccupyingNewPosition = true
    var isFirstMove: Bool
    dynamic var selected = false
    weak var player: Player?
    
    init(name: String, position: Position, isPossibleTranslation: @escaping (_ : Translation) -> Bool, isLegalMove: @escaping IsLegalMove) {
        self.name = name
        self.position = position
        self.startingPosition = position
        self.isPossibleTranslation = isPossibleTranslation
        self.isLegalMove = isLegalMove
        self.isFirstMove = true
    }
    
    required init(toCopy: Piece) {
        self.name = toCopy.name
        self.id = toCopy.id
        self.position = toCopy.position
        self.startingPosition = toCopy.position
        self.isPossibleTranslation = toCopy.isPossibleTranslation
        self.isLegalMove = toCopy.isLegalMove
        self.isFirstMove = toCopy.isFirstMove
        self.selected = toCopy.selected
        self.player = toCopy.player
    }
    
    deinit {
        print("deinit Piece")
    }
    
    func copy(with zone: NSZone?) -> Any {
        return type(of: self).init(toCopy: self)
    }
    
//    func canMove(translation: Translation) -> (isLegal: Bool, conditions: [(condition: Int, translations: [Translation]?)]?) {
//        
//    }
//    
}


private var myContext = 0
protocol PieceViewProtocol: class {
    func animateMove(_ pieceView: PieceView, position: Position, duration: TimeInterval)
}

class PieceView: UIView {
    var image: UIImage
    var positionConstraints = [NSLayoutConstraint]()
    weak var delegate: PieceViewProtocol?
    var observing: [(objectToObserve: NSObject, keyPath: String)]? {
        willSet {
            for observe in observing ?? [] {
                observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
            }
        }
        didSet {
            for observe in observing ?? [] {
                observe.objectToObserve.addObserver(self, forKeyPath: observe.keyPath, options: [.new, .old], context: &myContext)
            }
        }
    }

    init(image: UIImage, pieceTag: Int) {
        self.image = image
        super.init(frame: CGRect.zero)
        self.tag = pieceTag
        self.isUserInteractionEnabled = false
        
        // add imageView as subview
        let imageView = UIImageView(image:image)
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(NSLayoutConstraint.bindTopBottomLeftRight(imageView))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if keyPath == "selected" {
                if let new = change?[NSKeyValueChangeKey.newKey] as? Bool {
                    if new == true {
                        self.alpha = 0.4
                    } else {
                        self.alpha = 1.0
                    }
                }
            } else if keyPath == "position" {
                if let new = change?[NSKeyValueChangeKey.newKey] as? Position {
                    delegate?.animateMove(self, position: new, duration: 0.5)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        print("deinit PieceView")
        for observe in observing ?? [] {
            observe.objectToObserve.removeObserver(self, forKeyPath: observe.keyPath, context: &myContext)
        }
        observing = nil
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
