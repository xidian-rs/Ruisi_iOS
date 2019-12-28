//
//  PaddingLabel.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 带小尖头的label 用户消息页面
class ArrowLabel: UILabel {

    @IBInspectable var topInset: CGFloat = 9.0
    @IBInspectable var bottomInset: CGFloat = 3.0
    @IBInspectable var leftInset: CGFloat = 5.0
    @IBInspectable var rightInset: CGFloat = 5.0


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    override func draw(_ rect: CGRect) {
        let p2 = UIBezierPath()
        p2.move(to: CGPoint(x: rect.minX + 12, y: rect.minY + 6))
        p2.addLine(to: CGPoint(x: rect.minX + 22, y: rect.minY + 6))
        p2.addLine(to: CGPoint(x: rect.minX + 17, y: rect.minY))
        p2.close()
        
        let bg: UIColor
        if #available(iOS 13.0, *) {
            bg = UIColor.secondarySystemBackground
        } else {
            bg = UIColor(white: 0.96, alpha: 1)
        }
        bg.setFill()
        p2.fill()

        let bgPath = UIBezierPath(roundedRect: rect.offsetBy(dx: 0, dy: 6), cornerRadius: 3)
        bgPath.fill()
        super.draw(rect)
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
}
