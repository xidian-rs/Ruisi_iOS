//
//  StarData.swift
//  Ruisi
//
//  Created by yang on 2017/11/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class StarData {
    public var title: String
    public var tid: Int
    public var titleColor: UIColor? //文章颜色
    
    init(title:String,tid:Int,titleColor:UIColor? = nil) {
        self.title = title
        self.tid = tid
        self.titleColor = titleColor
    }
}
