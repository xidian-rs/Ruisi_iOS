//
//  PostData.swift
//  Ruisi
//
//  Created by yang on 2017/7/8.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class PostData {

    var content: String
    var author: String
    var uid: Int
    var time: String
    var pid: Int
    var index: String //楼层
    var replyUrl: String?

    init(content: String, author: String, uid: Int, time: String,
         pid: Int, index: String, replyUrl: String? = nil) {
        self.content = content
        self.author = author
        self.uid = uid
        self.pid = pid
        self.time = time
        self.index = index
        self.replyUrl = replyUrl
    }

}
