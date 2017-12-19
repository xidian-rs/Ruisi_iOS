//
//  Extension.swift
//  ImageViewer
//
//  Created by yang on 2017/12/17.
//  Copyright © 2015 MailOnline. All rights reserved.
//


import Foundation
import CoreGraphics
import UIKit

enum Direction {
    
    case left, right, up, down, none
}

enum Orientation {
    
    case vertical, horizontal, none
}

///Movement can be expressed as a vector in 2D coordinate space where the implied unit is 1 second and the vector point from 0,0 to an actual CGPoint value represents direction and speed. Then we can calculate convenient properties describing the nature of movement.
// MARK: - CGPoint
extension CGPoint {
    
    var direction: Direction {
        
        guard !(self.x == 0 && self.y == 0) else { return .none }
        
        if (abs(self.x) > abs(self.y) && self.x > 0) {
            
            return .right
        }
        else if (abs(self.x) > abs(self.y) && self.x <= 0) {
            
            return .left
        }
            
        else if (abs(self.x) <= abs(self.y) && self.y > 0) {
            
            return .up
        }
            
        else if (abs(self.x) <= abs(self.y) && self.y <= 0) {
            
            return .down
        }
            
        else {
            
            return .none
        }
    }
    
    var orientation: Orientation {
        
        guard self.direction != .none else { return .none }
        
        if self.direction == .left || self.direction == .right {
            return .horizontal
        }
        else {
            return .vertical
        }
    }
}

// MARK: - UIView
extension UIView {
    public var boundsCenter: CGPoint {
        return CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    }
}

