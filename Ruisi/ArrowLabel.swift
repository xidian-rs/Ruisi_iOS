//
//  PaddingLabel.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ArrowLabel: UILabel {
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    override func draw(_ rect: CGRect) {
        let p2 = UIBezierPath()
        p2.move(to: CGPoint(x: rect.minX+12, y: rect.minY+6))
        p2.addLine(to: CGPoint(x: rect.minX+22, y: rect.minY+6))
        p2.addLine(to: CGPoint(x: rect.minX+17, y: rect.minY))
        p2.close()
        let bg = UIColor(white: 0.95, alpha: 1)
        bg.setFill()
        p2.fill()
        
        
        let bgPath = UIBezierPath(roundedRect: rect.offsetBy(dx: 0, dy: 6), cornerRadius: 3)
      
        //let bg = UIColor(white: 0.95, alpha: 1)
        //bg.setFill()
        
        bgPath.fill()
        
        super.draw(rect)

    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 7, left: 3, bottom: 3, right: 3)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }

}
