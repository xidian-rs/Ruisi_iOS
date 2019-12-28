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
    
    var secondTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondaryLabel
        } else {
            return UIColor.darkText
        }
    }
    
    var thirdTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.tertiaryLabel
        } else {
            return UIColor.darkGray
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        for i in 0..<SmileyManager.shared.smileys.count {
            let btn = UIButton()
            btn.setTitle(SmileyManager.shared.smileys[i].name, for: [])
            btn.setTitleColor(thirdTextColor, for: .normal)
            btn.setTitleColor(secondTextColor, for: .selected)
            btn.setTitleColor(secondTextColor, for: .selected)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            
            btn.layer.cornerRadius = 0
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
    
    var btnBgSelected: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondarySystemBackground
        } else {
            return UIColor(white: 0.94, alpha: 1.0)
        }
    }
    
    var btnBg: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.tertiarySystemBackground
        } else {
            return UIColor.clear
        }
    }
    
    func selectItem(at position: Int) {
        for (k,item) in subviews.enumerated() {
            let btn =  item as! UIButton
            if k == position {
                // selected
                btn.backgroundColor = btnBgSelected
                btn.isSelected = true
            } else {
                btn.backgroundColor = btnBg
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
