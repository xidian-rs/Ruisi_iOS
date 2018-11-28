//
//  PostData.swift
//  Ruisi
//
//  Created by yang on 2017/7/8.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class PostData {

    var content: NSAttributedString
    var author: String
    var uid: Int
    var time: String
    var pid: Int
    var index: String //楼层
    var replyUrl: String?
    var voteData: VoteData? //投票
    
    public var rowHeight: CGFloat = 0

    init(content: NSAttributedString, author: String, uid: Int, time: String,
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
