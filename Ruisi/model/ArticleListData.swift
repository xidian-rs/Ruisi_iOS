//
//  ArticleListData.swift
//  Ruisi
//
//  Created by yang on 2017/6/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

// 文章列表数据元
public class ArticleListData {

    public var title: String
    public var tid: Int
    public var author: String
    public var replyCount: String
    public var isRead: Bool
    public var haveImage: Bool
    public var titleColor: UIColor? //文章颜色

    //校园网才有的
    public var uid: Int?
    public var views: String?
    public var time: String?

    //图片板块才有
    public var image: String?


    init(title: String, tid: Int, author: String = "未知", replys: String = "0",
         read: Bool = false, haveImage: Bool = false, titleColor: UIColor? = nil,
         uid: Int? = nil, views: String? = nil, time: String? = nil, image: String? = nil) {
        self.title = title
        self.tid = tid
        self.author = author
        self.replyCount = replys
        self.isRead = read
        self.haveImage = haveImage
        self.titleColor = titleColor

        self.uid = uid
        self.views = views
        self.time = time

        self.image = image
    }
}
