//
//  Constant.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public class App {
    public static var isLogin = false //是否登陆
    public static var isSchoolNet = false //是否是校园网
    public static var username:String? //用户名
    public static var uid: Int? // uid
    public static var grade: String? //等级
    public static var formHash: String? //fromhash
    
    //发布地址tid
    public static let POST_ID = 805203
    public static let HOST_RS = "rs.xidian.edu.cn"
}

public class Urls {
    public static let BASE_URL_EDU = "http://rs.xidian.edu.cn/"
    public static let BASE_URL_ME = "http://rsbbs.xidian.edu.cn/"
    
    public static var baseUrl:String{
        return App.isSchoolNet ? BASE_URL_EDU : BASE_URL_ME
    }
    
    // 签到 需要校园网
    public static let signUrl = "\(BASE_URL_EDU)plugin.php?id=dsu_paulsign:sign"
    public static let signPostUrl = "\(BASE_URL_EDU)plugin.php?id=dsu_paulsign:sign&operation=qiandao&infloat=1&inajax=1"
    
    public static var hotUrl:String{
        return baseUrl + "forum.php?mod=guide&view=hot&mobile=2"
    }
    
    public static var newUrl:String{
        return baseUrl + "forum.php?mod=guide&view=new&mobile=2"//&page=1
    }
    
    public static var loginUrl:String{
        return baseUrl + "member.php?mod=logging&action=login&mobile=2"
    }
    
    public static var checkUpdate: String {
        return getPostUrl(tid: App.POST_ID)
    }
    
    public static func getPostUrl(tid: Int) -> String {
        return "\(baseUrl)forum.php?mod=viewthread&tid=\(tid)&mobile=2"
    }
    
    public static func getPostsUrl(fid: Int) -> String {
        return "\(baseUrl)forum.php?mod=forumdisplay&fid=\(fid)&mobile=2" //&page=1
    }
    
    //回复
    public static var messageReply: String {
        return "\(baseUrl)home.php?mod=space&do=notice&mobile=2"
    }
    
    //pm
    public static var messagePm: String {
        return "\(baseUrl)home.php?mod=space&do=pm&mobile=2"
    }
    
    // 聊天详情页
    public static func getChatDetailUrl(tuid:Int) -> String {
        return "\(baseUrl)home.php?mod=space&do=pm&subop=view&touid=\(tuid)&mobile=2"
    }
    
    //at
    public static var messageAt: String {
        return "\(baseUrl)home.php?mod=space&do=notice&view=mypost&type=at&mobile=2"
    }
    
    //收藏
    public static func getStarUrl(uid:Int?) -> String {
        if uid == nil {
            return "\(baseUrl)home.php?mod=space&do=favorite&view=me&mobile=2"
        }
        return "\(baseUrl)home.php?mod=space&uid=\(uid!)&do=favorite&view=me&type=thread&mobile=2"
    }
    
    // 删除收藏 TODO 不支持外网
    public static func getDelStarUrl(favid:Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=favorite&op=delete&favid=\(favid)&type=all&inajax=1"
    }
    
    // 我的帖子
    public static func getMyPostsUrl(uid:Int?) -> String {
        if uid == nil {
            return "\(baseUrl)forum.php?mod=guide&view=my&mobile=2"
        }
        return "\(baseUrl)home.php?mod=space&uid=\(uid!)&do=thread&view=me&mobile=2"
    }
    
    // 我的好友
    public static var friendsUrl:String {
        return "\(baseUrl)home.php?mod=space&do=friend&mobile=2"
    }
    
    // 删除好友
    public static func deleteFriendUrl(uid: Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=friend&op=ignore&uid=\(uid)&confirm=1&mobile=2"
    }
    
    // 搜索用户
    public static func searchFriendUrl(username: String) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=search&username=\(username)&searchsubmit=yes&mobile=2"
    }
    
    // 添加好友
    public static func addFriendUrl(uid: Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=friend&op=add&uid=\(uid)&inajax=1&mobile=2"
    }
    
    
    // size =0 small 1-middle 2-large
    // 获得头像链接
    public static func getAvaterUrl(uid: Any, size: Int = 1) -> URL?{
        let sizeStr: String
        if size == 0 {
            sizeStr = "small"
        }else if size == 2 {
            sizeStr = "big"
        }else {
            sizeStr = "middle"
        }
        
        return URL(string: "\(baseUrl)ucenter/avatar.php?uid=\(uid)&size=\(sizeStr)&mobile=2")
    }
    
    // 获得用户详情页
    public static func getUserDetailUrl(uid:Any) -> String {
        return "\(baseUrl)home.php?mod=space&uid=\(uid)&do=profile&mobile=2"
    }
    
    // 搜索
    public static var searchUrl = "\(baseUrl)search.php?mod=forum&mobile=2"
    
    public static func getSearchUrl2(searchId:String) -> String {
        return "\(baseUrl)search.php?mod=forum&searchid=\(searchId)&orderby=lastpost&ascdesc=desc&searchsubmit=yes&mobile=2"
    }
    
    // 发帖url
    public static func newPostUrl(fid:Int) -> String {
        return "\(baseUrl)forum.php?mod=post&action=newthread&fid=\(fid)&mobile=2"
    }
}
