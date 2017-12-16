//
//  History.swift
//  Ruisi
//
//  Created by yang on 2017/11/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import CoreData

class History {
    public var tid: Int
    public var title: String
    public var author: String
    public var created: String
    public var lastRead: String
    
    init(tid:Int,title:String?,author:String?,created:String?,lastRead:String) {
        self.tid = tid
        self.title = title ?? "未知标题"
        self.author = author ?? "未知作者"
        self.created = created ?? ""
        self.lastRead = lastRead
    }
}
