//
//  LinkClickHandler.swift
//  Ruisi
//
//  Created by yang on 2017/12/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

// 默认的处理链接点击的函数
class LinkClickHandler {
    class func handle (url: String, delegate: ((LinkClickType) -> Void)) {
        // base http://rs.xidian.edu.cn/
        // asb  http://rs.xidian.edu.cn/forum.php?mod=viewthread&tid=862167&aid=871569&from=album&page=1&mobile=2
        print("url click", url)
        // 内部链接点击
        if url.hasPrefix(Urls.BASE_URL_EDU) || url.hasPrefix(Urls.BASE_URL_ME) {
            if url.contains("from=album") && url.contains("aid") { //点击了图片
                if let aid = Utils.getNum(prefix: "aid=", from: url) {
                    delegate(.viewAlbum(aid: aid, url: url))
                }
            } else if url.contains("forum.php?mod=viewthread&tid=") || url.contains("forum.php?mod=redirect&goto=findpost") { // 帖子
                if let tid = Utils.getNum(prefix: "tid=", from: url) {
                    delegate(.viewPost(tid: tid, pid: nil))
                }
            } else if url.contains("home.php?mod=space&uid=") { // 用户
                if let uid = Utils.getNum(prefix: "uid=", from: url) {
                    delegate(.viewUser(uid: uid))
                }
            } else if url.contains("forum.php?mod=post&action=newthread") {//发帖链接
                let fid = Utils.getNum(prefix: "fid=", from: url)
                delegate(.newPost(fid: fid))
            } else if url.contains("member.php?mod=logging&action=login") { //登陆
                delegate(.login())
            } else if url.contains("forum.php?mod=forumdisplay&fid=") { // 分区列表
                if let fid = Utils.getNum(prefix: "fid=", from: url) {
                    delegate(.viewPosts(fid: fid))
                }
            } else if url.contains("forum.php?mod=post&action=reply") { // 回复
                if let tid = Utils.getNum(prefix: "tid=", from: url) {
                    let pid = Utils.getNum(prefix: "pid=", from: url)
                    delegate(.reply(tid: tid, pid: pid))
                }
            } else if url.contains("forum.php?mod=attachment") { // 附件
                delegate(.attachment(url: url))
            } else {
                delegate(.others(url: url))
            }
        } else {
            delegate(.others(url: url))
        }
    }
}
