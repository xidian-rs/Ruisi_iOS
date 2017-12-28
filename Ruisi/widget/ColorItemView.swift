//
//  ColorItemView.swift
//  Ruisi
//
//  Created by yang on 2017/12/14.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ColorItemView: UIView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public var selected = false {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if self.selected {
            let p = UIBezierPath(arcCenter: CGPoint(x: rect.width / 2, y: rect.height / 2), radius: rect.width / 4, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
            UIColor.white.setFill()
            p.fill()
        }
    }
}
