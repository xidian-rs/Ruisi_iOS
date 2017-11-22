//
//  Common.swift
//  Ruisi
//
//  Created by yang on 2017/6/26.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

public class Widgets {
    
    // 设置下拉刷新样式
    public static func  setRefreshControl(_ target: UIRefreshControl) {
        target.backgroundColor = UIColor(white: 0.98, alpha: 1)
        target.tintColor = UIColor.gray
        target.attributedTitle = NSAttributedString(string: "下拉刷新",attributes: [
            NSAttributedStringKey.foregroundColor:UIColor.gray])
    }
    
}
