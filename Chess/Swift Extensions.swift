//
//  Swift Extensions.swift
//  Measure
//
//  Created by Roselle Milvich on 2/17/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


extension NSLayoutConstraint {
    class func centerHorizontally(view: UIView) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: view.superview, attribute: .CenterX, multiplier: 1, constant: 0)
    }
    class func centerVertically(view: UIView) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: view.superview, attribute: .CenterY, multiplier: 1, constant: 0)
    }
    class func bindLeftRight(view: UIView) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["view" :view])
    }
    class func bindTopBottom(view: UIView) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["view" :view])
    }
    
    class func bindTopBottomLeftRight(view: UIView) -> [NSLayoutConstraint] {
        return bindTopBottom(view) + bindLeftRight(view)
    }
    class func keepRatio(view: UIView) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
    }
    class func equalWidths(views: [UIView]) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        for i in 1..<views.count {
            let width = NSLayoutConstraint(item: views[i], attribute: .Width, relatedBy: .Equal, toItem: views[i-1], attribute: .Width, multiplier: 1, constant: 0)
            constraints.append(width)
        }
        return constraints
    }
    class func equalHeights(views: [UIView]) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        for i in 1..<views.count {
            let height = NSLayoutConstraint(item: views[i], attribute: .Height, relatedBy: .Equal, toItem: views[i-1], attribute: .Height, multiplier: 1, constant: 0)
            constraints.append(height)
        }
        return constraints
    }
    
    /// H:|[view1][view2][view3]|
    class func bindHorizontally(views: [UIView]) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        for i in 0..<views.count {
            let view = views[i]
            
            // leading
            var leading: NSLayoutConstraint
            if i == 0 { // bind first leading to superview
                leading = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Leading, relatedBy: .Equal, toItem: view.superview, attribute: .Leading, multiplier: 1, constant: 0)
            } else {    // bind all others to the previous view
                leading = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: views[i-1], attribute: .Trailing, multiplier: 1, constant: 0)
            }
            leading.identifier = "...leading i: \(i)"
            constraints.append(leading)
        }
        
        if views.last != nil {
            let trailing = NSLayoutConstraint(item: views.last!, attribute: .Trailing, relatedBy: .Equal, toItem: views.last!.superview, attribute: .Trailing, multiplier: 1, constant: 0)
            trailing.identifier = "...trailing view: \(views.count)"
            constraints.append(trailing)
        }
        
        return constraints
    }
    
    /// V:|[view1][view2][view3]|
    class func bindVertically(views: [UIView]) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        for i in 0..<views.count {
            let view = views[i]
            
            // top
            var top: NSLayoutConstraint
            if i == 0 {
                
                // bind first top to superview
                top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: .Equal, toItem: view.superview, attribute: .Leading, multiplier: 1, constant: 0)
            } else {
                
                // bind all others to the previous view
                top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: views[i-1], attribute: .Bottom, multiplier: 1, constant: 0)
            }
            constraints.append(top)
        }
        
        // bottom
        var bottom: NSLayoutConstraint
        if views.last != nil {
            // bind last bottom to superview
            bottom = NSLayoutConstraint(item: views.last!, attribute: .Bottom, relatedBy: .Equal, toItem: views.last!.superview, attribute: .Bottom, multiplier: 1, constant: 0)
            bottom.identifier = "...last: \(views.count)"
            constraints.append(bottom)
        }
        
        return constraints
    }
}

//
//extension Int {
//    func withSuffix() -> String {
//        var suffix: String
//        let lastDigit = self % 10
//        switch lastDigit {
//        case 0 where self == 0:
//            suffix = ""
//        case 1 where self != 11:
//            suffix = "st"
//        case 2 where self != 12:
//            suffix = "nd"
//        case 3 where self != 13:
//            suffix = "rd"
//        default:
//            suffix = "th"
//        }
//        return "\(self)" + suffix
//    }
//    
//    func stringForPinNumber(number: Int) -> String {
//        var string: String
//        switch number {
//        case 0:
//            string = "1st Point"
//        case 1:
//            string = "2nd Point"
//        case 2:
//            string = "3rd Point"
//        default:
//            string = "\(number+1)th Point"
//        }
//        return string
//    }
//}
//
//
//extension CLLocationCoordinate2D {
//    // In meteres
//    func distance(to to:CLLocationCoordinate2D) -> CLLocationDistance {
//        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
//        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
//        return from.distanceFromLocation(to)
//    }
//    
//    func halfway(to: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
//        return CLLocationCoordinate2D(latitude: (self.latitude + to.latitude)/2, longitude: (self.longitude + to.longitude)/2)
//    }
//}
//
//extension CLLocationDistance {
//    func inKilometers() -> Double {
//        return self * 0.001
//    }
//    
//    func inFeet() -> Double {
//        return self * 3.28084
//    }
//    
//    func inYards() -> Double {
//        return self * 1.09361329834
//    }
//    
//    func inMiles() -> Double {
//        return self * 0.000621371
//    }
//}
//
//extension MKMapPoint {
//    /**
//     - parameters:
//        - poly: MKPolyline The polyline to measure to
//     - returns: The closest point to the line and its distance     
//     - note: I haven't checked the math on this.
//     http://stackoverflow.com/questions/11713788/how-to-detect-taps-on-mkpolylines-overlays-like-maps-app
//     https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
//     */
//    func closestPointAndDistance(poly: MKPolyline) -> (point: MKMapPoint, distance: CLLocationDistance) {
//        let polyPoints = poly.points()
//        var distance = Double(MAXFLOAT)
//        var closestPointOnLine = polyPoints[0]
//        for i in 0..<poly.pointCount - 1 {
//            let ptA = polyPoints[i]
//            let ptB = polyPoints[i + 1]
//            let xDelta = ptB.x - ptA.x
//            let yDelta = ptB.y - ptA.y
//            
//            // initial values in case ptA and ptB are equal
//            var ptClosest = ptA
//            var newDistance = MKMetersBetweenMapPoints(ptClosest, self)
//            
//            if xDelta != 0 && yDelta != 0 {
//                let u = ((self.x - ptA.x) * xDelta + (self.y - ptA.y) * yDelta) / (xDelta * xDelta + yDelta * yDelta)
//                if u < 0.0 {
//                    ptClosest = ptA
//                    
//                } else if u > 1.0 {
//                    ptClosest = ptB
//                } else {
//                    ptClosest = MKMapPointMake(ptA.x + u * xDelta, ptA.y + u * yDelta)
//                }
//                newDistance = MKMetersBetweenMapPoints(ptClosest, self)
//            }
//            if newDistance < distance {
//                distance = newDistance
//                closestPointOnLine = ptClosest
//            }
//        }
//        return (closestPointOnLine, distance)
//    }
//}
//
//extension MKPolyline {
//    func midPoint() -> MKMapPoint {
//        let points = self.points()
//        let coordinate1 = MKCoordinateForMapPoint(points[0])
//        let coordinate2 = MKCoordinateForMapPoint(points[pointCount-1])
//        let halfwayCoordinate = coordinate1.halfway(coordinate2)
//        let halfwayMapPoint = MKMapPointForCoordinate(halfwayCoordinate)
//        return halfwayMapPoint.closestPointAndDistance(self).point
//    }
//}
//
//extension Double {
//    
//    func string(numOfDigits:Int) -> String {
//        struct Holder {
//            static let formatter = NSNumberFormatter()
//        }
//        Holder.formatter.minimumFractionDigits = numOfDigits
//        Holder.formatter.maximumFractionDigits = numOfDigits
//        Holder.formatter.numberStyle = .DecimalStyle
//        return Holder.formatter.stringFromNumber(self) ?? "\(self)"
//    }
//}
//
//extension UILabel {
//    class func wrappingLabel(text: String) -> UILabel {
//        let label = UILabel()
//        label.text = text
//        label.numberOfLines = 0
//        label.lineBreakMode = .ByWordWrapping
//        return label
//    }
//}
//
//extension CLLocationCoordinate2D {
//    func latitudeStringWithCardinalDirections() -> String {
//        let cardinal = self.latitude < 0 ? "° S" : "° N"
//        let number = self.latitude < 0 ? self.latitude * -1 : self.latitude
//        return number.string(5) + cardinal
//    }
//    func longitudeStringWithCardinalDirections() -> String {
//        let cardinal = self.longitude < 0 ? "° W" : "° E"
//        let number = self.longitude < 0 ? self.longitude * -1 : self.longitude
//        return number.string(5) + cardinal
//    }
//}
//
//func delay(delay:Double, closure:()->()) {
//    dispatch_after(
//        dispatch_time(
//            DISPATCH_TIME_NOW,
//            Int64(delay * Double(NSEC_PER_SEC))
//        ),
//        dispatch_get_main_queue(), closure)
//}
///*
// delay(0.4) {
// // do stuff
// }
// */
