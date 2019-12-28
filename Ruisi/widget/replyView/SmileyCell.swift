//
//  SmileyCell.swift
//  SmileyView
//
//  Created by yang on 2017/12/20.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

protocol SmileyCellDelegate {
    // item 为nil代表点击了删除按钮
    func smileyCellDidSelectAt(cell:UICollectionViewCell,item: SmileyItem?)
}

class SmileyCell: UICollectionViewCell {
    
    public var delegate: SmileyCellDelegate?
    public var rowCount = 3
    public var columnCount = 7
    
    public var pageSize: Int {
        return (columnCount * rowCount) - 1
    }
    
    private var smileys: [SmileyItem]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUi()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("you shou init this view in code!")
    }
    
    var titleColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondaryLabel
        } else {
            return UIColor.darkText
        }
    }
    
    var titleColorSelected: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.tertiaryLabel
        } else {
            return UIColor.darkGray
        }
    }
    
    func setupUi() {
        let leftMargin: CGFloat = 8
        let bottomMargin: CGFloat = 0
        
        let w = (bounds.width - 2 * leftMargin) / CGFloat(columnCount)
        let h = (bounds.height - bottomMargin) / CGFloat(rowCount)
        
        for r in 0..<rowCount {
            for c in 0..<columnCount {
                let x = leftMargin + CGFloat(c) * w
                let y = CGFloat(r) * h
                let btn = UIButton(frame: CGRect(x: x, y: y, width: w, height: h))
                btn.setTitleColor(titleColor, for: .normal)
                btn.setTitleColor(titleColorSelected, for: .highlighted)
                btn.addTarget(self, action: #selector(smileyClick), for: .touchUpInside)
                btn.tag = r * columnCount + c
                //btn.sizeToFit()
                contentView.addSubview(btn)
            }
        }
    }
    
    func setSmileys(smileys: [SmileyItem]) {
        self.smileys = smileys
        for i in 0..<rowCount {
            for j in 0..<columnCount {
                let index = i * columnCount + j
                if index == rowCount * columnCount - 1 {
                    // delete btn
                    let btn =  contentView.subviews.last as! UIButton
                    btn.isHidden = false
                    btn.setImage(#imageLiteral(resourceName: "backspace"), for: [])
                    let insetV = (btn.frame.size.height - 26) / 2
                    let insetH = (btn.frame.size.width - 38) / 2
                    btn.imageEdgeInsets = UIEdgeInsets(top: (insetV < 0) ? 0: insetV, left: (insetH < 0) ? 0: insetH, bottom: (insetV < 0) ? 0: insetV, right: (insetH < 0) ? 0: insetH)
                } else if index > smileys.count - 1 {
                    contentView.subviews[index].isHidden = true
                } else {
                    let btn =  contentView.subviews[index] as! UIButton
                    btn.isHidden = false
                    if let image = smileys[index].image {
                        let minSize = min(btn.frame.size.width, btn.frame.size.height)
                        if minSize > 40 {
                            let insetV = (btn.frame.size.height - 40) / 2
                            let insetH = (btn.frame.size.width - 40) / 2
                            btn.imageEdgeInsets = UIEdgeInsets(top: insetV, left: insetH, bottom: insetV, right: insetH)
                        }
                        btn.setTitle(nil, for: [])
                        btn.setImage(image, for: [])
                    }else {
                        btn.titleEdgeInsets = UIEdgeInsets.zero
                        btn.setImage(nil, for: [])
                        btn.setTitle(smileys[index].value, for: [])
                    }
                }
                
            }
        }
    }
    
    @objc func smileyClick(_ btn: UIButton) {
        let item = (btn.tag < smileys.count) ? smileys[btn.tag] : nil
        delegate?.smileyCellDidSelectAt(cell: self, item: item)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUi()
    }
}


