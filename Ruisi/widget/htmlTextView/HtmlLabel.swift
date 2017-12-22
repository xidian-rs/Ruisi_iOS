//
//  HtmlLabel.swift
//  Ruisi
//
//  Created by yang on 2017/12/22.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class HtmlLabel: UILabel {

    var delegate: ((LinkClickType) -> Void)?
    var htmlText: String? {
        didSet {
            if let text = htmlText {
                attributedText = AttributeConverter(font: UIFont.systemFont(ofSize: 16), textColor: UIColor.darkText).convert(src: text)
            } else {
                attributedText = nil
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        textColor = UIColor.darkText
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded\(event?.type.rawValue)")
    }
}
