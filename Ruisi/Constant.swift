//
//  Constant.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation



public class App {
    //发布地址tid
    public static let POST_ID = 805203
    public static var isLogin = false //是否登陆
    public static var username:String? //用户名
    public static var uid: Int? // uid
    public static var grade: String? //等级
}

public class Urls {
    public static var baseUrl:String{
        return BASE_URL_ME
    }
    
    public static let BASE_URL = "http://rs.xidian.edu.cn/"
    public static let BASE_URL_ME = "http://bbs.rs.xidian.me/"
    
    // 签到
    public static let signUrl = "\(BASE_URL)plugin.php?id=dsu_paulsign:sign"
    public static let signPostUrl = "\(BASE_URL)plugin.php?id=dsu_paulsign:sign&operation=qiandao&infloat=1&inajax=1"
    
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
    
    //at
    public static var messageAt: String {
        return "\(baseUrl)home.php?mod=space&do=notice&view=mypost&type=at&mobile=2"
    }
    
    
    // size =0 small 1-middle 2-large
    public static func getAvaterUrl(uid: Int, size: Int = 1) -> String {
        let sizeStr: String
        if size == 0 {
            sizeStr = "small"
        }else if size == 2 {
            sizeStr = "big"
        }else {
            sizeStr = "middle"
        }
        
        return "\(baseUrl)ucenter/avatar.php?uid=\(uid)&size=\(sizeStr)&mobile=2"
    }
    
}
