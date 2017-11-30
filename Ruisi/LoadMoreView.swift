//
//  LoadMoreView.swift
//  Ruisi
//
//  Created by yang on 2017/6/26.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class LoadMoreView: UIView {

    var contentView : UIView!
    var indicate: UIActivityIndicatorView!
    var label: UILabel!
    var isLoading: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        contentView = loadViewFromNib()
        contentView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        label = contentView.viewWithTag(2) as! UILabel
        label.text = "正在加载"
        indicate = contentView.viewWithTag(1) as! UIActivityIndicatorView
        // use bounds not frame or it'll be offset
        contentView.frame = bounds
        
        // Make the view stretch with containing view
        contentView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(contentView)
    }
    
    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    func startLoading() {
        if !isLoading {
            indicate.startAnimating()
            label.text = "正在加载"
            isLoading = true
        }
    }
    
    // 是否加载成功 是否有更多数据
    func endLoading(success: Bool = true,haveMore: Bool = false) {
        if isLoading {
            if success {
                if haveMore {
                    label.text = "上拉加载更多"
                }else {
                    label.text = "暂无更多,上拉重新加载"
                }
            }else {
                label.text = "加载失败,上拉重新加载"
            }
            
            indicate.stopAnimating()
            isLoading = false
        }
    }
}
