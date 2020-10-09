//
//  Constant.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public class App {
    //是否登录
    public static var isLogin: Bool {
        return Settings.uid != nil
    }
    
    //是否是校园网
    public static var isSchoolNet = false
    
    //App ID
    public static let APP_ID = "id1322805454"
    
    //发布地址tid
    public static let POST_ID = 921699
    public static let HOST_RS = "rs.xidian.edu.cn"
}

public class Urls {
    //校园网地址
    public static let BASE_URL_EDU = "http://rs.xidian.edu.cn/"
    //校外网地址
    public static let BASE_URL_ME = "http://rsbbs.xidian.edu.cn/"
    
    public class var baseUrl: String {
        return App.isSchoolNet ? BASE_URL_EDU : BASE_URL_ME
    }

    // 签到 需要校园网
    public static let signUrl = "\(BASE_URL_EDU)plugin.php?id=dsu_paulsign:sign"
    public static let signPostUrl = "\(BASE_URL_EDU)plugin.php?id=dsu_paulsign:sign&operation=qiandao&infloat=1&inajax=1"

    public class var hotUrl: String {
        return "\(baseUrl)forum.php?mod=guide&view=hot&mobile=2"
    }

    public class var newUrl: String {
        return "\(baseUrl)forum.php?mod=guide&view=new&mobile=2"//&page=1
    }

    // 登录
    public class var loginUrl: String {
        return "\(baseUrl)member.php?mod=logging&action=login&mobile=2"
    }
    
    // 检查登录
    public class var checkLoginUrl: String {
        return "\(baseUrl)member.php?mod=logging&action=login&inajax=1&mobile=2"
    }
    
    public class var checkLoginUrlInner: String {
        return "\(BASE_URL_EDU)member.php?mod=logging&action=login&inajax=1&mobile=2"
    }
    
    public class var checkLoginUrlOut: String {
        return "\(BASE_URL_ME)member.php?mod=logging&action=login&inajax=1&mobile=2"
    }
    
    // 注册检测的地址，检查用户名/邮箱/邀请码是否合法
    public class var regCheckUrl: String {
        return "\(baseUrl)forum.php?mod=ajax&inajax=1&mobile=2"
    }
    
    // 忘记密码
    public class var forgetPasswordUrl: String {
        return "\(baseUrl)member.php?mod=lostpasswd&lostpwsubmit=yes&inajax=1&mobile=2"
    }
    
    // 修改密码 修改邮箱
    public class var passwordSafeUrl: String {
        return "\(baseUrl)home.php?mod=spacecp&ac=profile&op=password&mobile=2&inajax=1"
    }
    
    public class var passwordSafePostUrl: String {
        return "\(baseUrl)home.php?mod=spacecp&ac=profile&mobile=2&inajax=1"
    }
    
    public class var resentEmailUrl: String {
        return "\(baseUrl)home.php?mod=spacecp&ac=profile&op=password&resend=1&mobile=2&inajax=1"
    }

    public class var checkUpdate: String {
        return getPostUrl(tid: App.POST_ID)
    }
    
    // 板块列表
    public class var forumlistUrl: String {
        return "\(baseUrl)forum.php?inajax=1&forumlist=1&mobile=2"
    }

    public class func getPostUrl(tid: Int, pid: Int? = nil) -> String {
        if let p = pid {
            return "\(baseUrl)forum.php?mod=redirect&goto=findpost&ptid=\(tid)&pid=\(p)&mobile=2"
        }
        return "\(baseUrl)forum.php?mod=viewthread&tid=\(tid)&mobile=2"
    }

    // 帖子列表
    public class func getPostsUrl(fid: Int) -> String {
        if !Settings.showFullStylePosts {
            return "\(baseUrl)forum.php?mod=forumdisplay&fid=\(fid)&mobile=2" //&page=1
        }
        return "\(baseUrl)forum.php?mod=forumdisplay&fid=\(fid)&mobile=no" //&page=1
    }

    public class func getPostsType(fid: Int, isSchoolNet: Bool) -> PostsType {
        if !Settings.showFullStylePosts {
            return .list
        }
        if fid == 157 || fid == 561 || fid == 13 {
            // 图片板块
            return .imageGrid
        }

        return .listWithImage //校园网样式
    }

    //回复
    public class var messageReply: String {
        return "\(baseUrl)home.php?mod=space&do=notice&inajax=1&mobile=2"
    }

    //pm
    public static var messagePm: String {
        return "\(baseUrl)home.php?mod=space&do=pm&mobile=2"
    }

    // 聊天详情页
    public class func getChatDetailUrl(tuid: Int) -> String {
        return "\(baseUrl)home.php?mod=space&do=pm&subop=view&touid=\(tuid)&mobile=2"
    }
    
    // 发送聊天
    public class func postChatUrl(tuid: Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=pm&op=send&pmid=\(tuid)&daterange=0&pmsubmit=yes&mobile=2"
    }

    //at
    public class var messageAt: String {
        return "\(baseUrl)home.php?mod=space&do=notice&view=mypost&type=at&inajax=1&mobile=2"
    }

    // 我的收藏
    public class var starUrl: String {
        return "\(baseUrl)home.php?mod=space&do=favorite&view=me&mobile=2"
    }

    // 收藏文章
    public class func addStarUrl(tid: Any) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=favorite&type=thread&id=\(tid)&mobile=2&handlekey=favbtn&inajax=1"
    }


    // 删除收藏 TODO 不支持外网
    public class func getDelStarUrl(favid: Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=favorite&op=delete&favid=\(favid)&type=all&inajax=1"
    }

    // 我的帖子
    public static func getMyPostsUrl(uid: Int?) -> String {
        if uid == nil {
            return "\(baseUrl)forum.php?mod=guide&view=my&mobile=2"
        }
        return "\(baseUrl)home.php?mod=space&uid=\(uid!)&do=thread&view=me&mobile=2"
    }
    
    // 我的金币
    public class var myMoneyUrl: String {
        return "\(baseUrl)home.php?mod=spacecp&ac=credit&showcredit=1&inajax=1&mobile=2"
    }
    
    // 我的回复
    public class var myReplysUrl: String {
        return "\(baseUrl)forum.php?mod=guide&view=my&type=reply&inajax=1&mobile=2"
    }

    // 我的好友
    public static var friendsUrl: String {
        return "\(baseUrl)home.php?mod=space&do=friend&mobile=2"
    }

    // 删除好友
    public class func deleteFriendUrl(uid: Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=friend&op=ignore&uid=\(uid)&confirm=1&mobile=2"
    }

    // 搜索用户
    public class var searchFriendUrl: String {
        return "\(baseUrl)home.php?mod=spacecp&ac=search&searchsubmit=yes&mobile=2"
    }

    // 添加好友
    public class func addFriendUrl(uid: Int) -> String {
        return "\(baseUrl)home.php?mod=spacecp&ac=friend&op=add&uid=\(uid)&inajax=1&mobile=2"
    }


    // size =0 small 1-middle 2-large
    // 获得头像链接
    public class func getAvaterUrl(uid: Any, size: Int = 1) -> URL? {
        let sizeStr: String
        if size == 0 {
            sizeStr = "small"
        } else if size == 2 {
            sizeStr = "big"
        } else {
            sizeStr = "middle"
        }

        return URL(string: "\(baseUrl)ucenter/avatar.php?uid=\(uid)&size=\(sizeStr)&mobile=2")
    }

    // 获得用户详情页
    public class func getUserDetailUrl(uid: Any) -> String {
        return "\(baseUrl)home.php?mod=space&uid=\(uid)&do=profile&mobile=2"
    }

    // 搜索
    public static var searchUrl = "\(baseUrl)search.php?mod=forum&mobile=2"

    public class func getSearchUrl2(searchId: String) -> String {
        return "\(baseUrl)search.php?mod=forum&searchid=\(searchId)&orderby=lastpost&ascdesc=desc&searchsubmit=yes&mobile=2"
    }

    // 发帖url
    public class func newPostUrl(fid: Int) -> String {
        return "\(baseUrl)forum.php?mod=post&action=newthread&fid=\(fid)&mobile=2"
    }

    // 提交编辑url
    public class var editSubmitUrl: String {
        return "\(baseUrl)forum.php?mod=post&action=edit&extra=&editsubmit=yes&mobile=2"
    }

    // 编辑帖子URL
    public class func editPostUrl(tid: Int, pid: Int) -> String {
        return "\(baseUrl)forum.php?mod=post&action=edit&tid=\(tid)&pid=\(pid)&mobile=2"
    }

    // @列表
    public class var AtListUrl: String {
        return "\(baseUrl)misc.php?mod=getatuser&inajax=1&mobile=2"
    }

    // 浏览帖子图片列表
    public class func viewAlbumUrl(tid: Int, aid: Int?) -> String {
        return "\(baseUrl)forum.php?mod=viewthread&tid=\(tid)&from=album&mobile=2\((aid != nil) ? "&aid=\(aid!)" : "")"
    }


    // 上传图片
    public class var uploadImageUrl: String {
        return "\(baseUrl)misc.php?mod=swfupload&operation=upload&type=image&inajax=yes&infloat=yes&simple=2&mobile=2"
    }

    // 删除上传的图片
    public class func deleteUploadedUrl(aid: String) -> String {
        return "\(baseUrl)forum.php?mod=ajax&action=deleteattach&inajax=yes&aids[]=\(aid)&mobile=2"
    }
    
    // 检查发帖需不需要输入验证码
    public class var checkNewpostUrl: String {
        return "\(baseUrl)forum.php?mod=ajax&action=checkpostrule&ac=newthread&mobile=2"
    }
    
    // 更新验证码图片地址
    public class func updateValidUrl(update: String, hash: String) -> String {
        return "\(baseUrl)misc.php?mod=seccode&update=\(update)&idhash=\(hash)&mobile=2"
    }
    
    // 查询update地址
    public class func getValidUpdateUrl(hash: String) -> String {
        return "\(baseUrl)misc.php?mod=seccode&action=update&idhash=\(hash)&mobile=2"
    }
    
    // 检查验证码是否正确
    public class func checkValidUrl(hash: String, value: String) -> String {
        return "\(baseUrl)misc.php?mod=seccode&action=check&inajax=1&idhash=\(hash)&secverify=\(value)&mobile=2"
    }
}
