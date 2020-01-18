//
//  LinkClickType.swift
//  HtmlTextView
//
//  Created by yang on 2017/12/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

// HTML 里面的链接点击事件
public enum LinkClickType {
    case viewPost(tid: Int, pid: Int?) // 查看某贴的链接被点击
    case viewAlbum(aid: Int, url: String) // 查看某贴的图片
    case viewUser(uid: Int) // 查看用户详情
    case newPost(fid: Int?) // 发帖
    case viewPosts(fid: Int) // 帖子列表
    case reply(tid: Int, pid: Int?) // 回复
    case attachment(url: String) // 附件
    case login // 登录
    case vote(fid: Int, tid: Int) // 投票
    case others(url: String) // 其余
}
