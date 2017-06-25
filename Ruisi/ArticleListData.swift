//
//  ArticleListData.swift
//  Ruisi
//
//  Created by yang on 2017/6/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

// 文章列表数据元
public class ArticleListDataSimple {
    public var title: String
    public var tid: Int
    public var author: String
    public var replyCount: String
    public var isRead: Bool
    public var haveImage: Bool
    public var titleColor: Int? //文章颜色
    
    init(title:String,tid: Int,author:String,replys:String,read:Bool = false,haveImage:Bool = false,titleColor:Int? = nil) {
        self.title = title
        self.tid = tid
        self.author = author
        self.replyCount = replys
        self.isRead = read
        self.haveImage = haveImage
        self.titleColor = titleColor
    }
}
