//
//  HtmlNode.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class HtmlNode {
    var type: HtmlTag = .UNKNOWN //type
    var name: String
    var start: Int = 0
    var end: Int = 0
    var attr: HtmlAttr?
    
    init(type: HtmlTag,name: String, attr: HtmlAttr? = nil) {
        self.type = type
        self.name = name
        self.attr = attr
    }
}
