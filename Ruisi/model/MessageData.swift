//
//  MessageData.swift
//  Ruisi
//
//  Created by yang on 2017/7/9.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class MessageData {

    var type: MessageType
    var title: String
    var tid: Int
    var pid: Int?
    var author: String
    var uid: Int? // 系统无uid
    var time: String
    var content: String
    var isRead: Bool
    
    var rowHeight: CGFloat = 0

    init(type: MessageType, title: String, tid: Int, pid: Int?, uid: Int?, author: String,
         time: String, content: String = "", isRead: Bool = true) {
        self.type = type
        self.title = title
        self.tid = tid
        self.pid = pid
        self.uid = uid
        self.author = author
        self.time = time
        self.content = content
        self.isRead = isRead
    }
}

enum MessageType {
    case Reply
    case Pm
    case At
}
