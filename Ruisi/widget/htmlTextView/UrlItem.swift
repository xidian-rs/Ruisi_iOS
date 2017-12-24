//
//  UrlItem.swift
//  Ruisi
//
//  Created by yang on 2017/12/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class UrlItem {
    public var url: String
    public var range: NSRange
    
    init(url: String, range: NSRange) {
        self.url = url
        self.range = range
    }
}
