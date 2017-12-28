//
//  TagLabel.swift
//  Ruisi
//
//  Created by yang on 2017/12/26.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// tag 的label
class TagLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    private func setUp() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 2
        //007AFF
        self.backgroundColor = ThemeManager.currentPrimaryColor
        self.textColor = UIColor.white
        self.font = UIFont.systemFont(ofSize: 9)
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += 2
            contentSize.width += 4
            return contentSize
        }
    }
}
