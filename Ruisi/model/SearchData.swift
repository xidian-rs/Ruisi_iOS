//
//  SearchData.swift
//  Ruisi
//
//  Created by yang on 2017/12/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class SearchData {
    public var tid: Int
    public var title: NSAttributedString
    public var rowHeight: CGFloat = 0
    
    init(tid: Int, title: NSAttributedString) {
        self.tid = tid
        self.title = title
    }
}
