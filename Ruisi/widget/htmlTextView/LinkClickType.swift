//
//  LinkClickType.swift
//  HtmlTextView
//
//  Created by yang on 2017/12/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public enum LinkClickType {
    case viewPost(tid: Int, pid: Int?)
    case viewAlbum(aid: Int,url: String)
    case viewUser(uid: Int)
    case newPost(fid: Int?)
    case viewPosts(fid: Int)
    case reply(tid: Int,pid: Int?)
    case attachment(url: String)
    case login()
    case others(url: String)
}
