//
//  SmileyToolbar.swift
//  SmileyView
//
//  Created by yang on 2017/12/20.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 表情底部工具栏
class SmileyToolbar: UIView {
    
    public var itemSelected: ((_ btn: UIButton,_ position: Int)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        for i in 0..<SmileyManager.shared.smileys.count {
            let btn = UIButton()
            btn.setTitle(SmileyManager.shared.smileys[i].name, for: [])
            btn.setTitleColor(UIColor.darkGray, for: .normal)
            btn.setTitleColor(UIColor.darkText, for: .selected)
            btn.setTitleColor(UIColor.darkText, for: .selected)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            
            btn.layer.cornerRadius = 0
            btn.layer.borderWidth = 0.25
            btn.layer.borderColor = UIColor.lightGray.cgColor
            btn.layer.masksToBounds = true
            
            btn.tag = i
            btn.sizeToFit()
            
            btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
            addSubview(btn)
        }
        
        selectItem(at: 0)
    }
    
    @objc func btnClick(_ btn: UIButton)  {
        selectItem(at: btn.tag)
        itemSelected?(btn, btn.tag)
    }
    
    func selectItem(at position: Int) {
        for (k,item) in subviews.enumerated() {
            let btn =  item as! UIButton
            if k == position {
                btn.backgroundColor = UIColor(white: 0.94, alpha: 1.0)
                btn.isSelected = true
            } else {
                btn.backgroundColor = UIColor.clear
                btn.isSelected = false
            }
        }
    }
    
    override func layoutSubviews() {
        //super.layoutSubviews()
        let cont = subviews.count
        let w = bounds.width / CGFloat(cont)
        
        for (index, btn) in subviews.enumerated() {
            let x =  CGFloat(index) * w
            btn.frame = CGRect(x: x, y: 0, width: w, height: bounds.height)
        }
    }
}
