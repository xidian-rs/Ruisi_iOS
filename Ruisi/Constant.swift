//
//  Constant.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

var isLogin = false //是否登陆

public class App {
    //发布地址tid
    public static let POST_ID = 805203
}

public class Urls {
    public static var baseUrl:String{
        return BASE_URL_ME
    }
    
    public static let BASE_URL = "http://rs.xidian.edu.cn/"
    public static let BASE_URL_ME = "http://bbs.rs.xidian.me/"
    
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
}
