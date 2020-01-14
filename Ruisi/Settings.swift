//
//  Settings.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

// 首选项管理类
public class Settings {
    private static let key_avater = "key_avater"
    private static let key_uid = "key_uid"
    private static let key_username = "key_username"
    private static let key_password = "key_password"
    private static let key_grade = "key_grade"
    private static let key_formhash = "key_formhash"
    private static let key_rember_password = "key_rember_password"
    private static let key_enable_tail = "key_enable_tail"
    private static let key_tail_content = "key_tail_content"
    private static let key_show_zhiding = "key_show_zhiding"
    private static let key_message_id_reply = "key_message_id_reply"
    private static let key_message_id_pm = "key_message_id_pm"
    private static let key_message_id_at = "key_message_id_at"
    private static let key_theme_id = "key_theme_id"
    private static let key_forumlist = "key_forumlist"
    private static let key_post_use_uitextview = "key_post_use_uitextview"
    private static let key_forumlist_display_type = "key_forumlist_display_type"
    private static let key_forumlist_saved_time = "key_forumlist_saved_time"
    private static let key_work_type = "key_work_type"
    private static let key_select_subforum = "key_select_subforum"
    
    static func getMessageId(type: Int) -> Int {
        switch type {
        case 0:
            return UserDefaults.standard.integer(forKey: key_message_id_reply)
        case 1:
            return UserDefaults.standard.integer(forKey: key_message_id_pm)
        case 2:
            return UserDefaults.standard.integer(forKey: key_message_id_at)
        default:
            return 0
        }
    }

    static func setMessageId(type: Int, value: Int) {
        switch type {
        case 0:
            return UserDefaults.standard.set(value, forKey: key_message_id_reply)
        case 1:
            return UserDefaults.standard.set(value, forKey: key_message_id_pm)
        case 2:
            return UserDefaults.standard.set(value, forKey: key_message_id_at)
        default:
            return
        }
    }
    
    // 用户id
    public static var uid: Int? {
        get {
            let uid = UserDefaults.standard.integer(forKey: key_uid)
            return uid > 0 ? uid : nil
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: key_uid)
        }
    }

    //用户名
    public static var username: String? {
        get {
            return UserDefaults.standard.string(forKey: key_username)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_username)
        }
    }
    
    //用户等级
    public static var grade: String? {
        get {
            return UserDefaults.standard.string(forKey: key_grade)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: key_grade)
        }
    }
    
    //formhash
    public static var formhash: String? {
        get {
            return UserDefaults.standard.string(forKey: key_formhash)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: key_formhash)
        }
    }

    //密码
    public static var password: String? {
        get {
            return UserDefaults.standard.string(forKey: key_password)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_password)
        }
    }

    //是否记住密码
    public static var remberPassword: Bool {
        get {
            return UserDefaults.standard.bool(forKey: key_rember_password)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_rember_password)
        }
    }
    
    // 是否关闭最近常逛的版块
    public static var closeRecentVistForum: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "key_close_recent_vist_forum")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "key_close_recent_vist_forum")
        }
    }

    // 显示置顶
    public static var showZhiding: Bool {
        get {
            return UserDefaults.standard.bool(forKey: key_show_zhiding)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_show_zhiding)
        }
    }

    // 当前主题
    public static var currentTheme: Int {
        get {
            return UserDefaults.standard.integer(forKey: key_theme_id)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_theme_id)
        }
    }
    
    // 帖子正文渲染方式
    // true - UILabel
    // false - UITextView
    public static var postContentRenderType: Bool {
        get {
            return UserDefaults.standard.bool(forKey: key_post_use_uitextview)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: key_post_use_uitextview)
        }
    }

    // 允许小尾巴
    public static var enableTail: Bool {
        get {
            return UserDefaults.standard.bool(forKey: key_enable_tail)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_enable_tail)
        }
    }

    // 小尾巴内容
    public static var tailContent: String? {
        get {
            return UserDefaults.standard.string(forKey: key_tail_content)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: key_tail_content)
        }
    }
    
    // choosed subforum 选择的子板块
    public static func setSelectSubForum(fid: Int, subForum: Forum) {
        UserDefaults.standard.set(subForum.fid, forKey: "\(key_select_subforum)_\(fid)_fid")
        UserDefaults.standard.set(subForum.name, forKey: "\(key_select_subforum)_\(fid)_title")
    }
    
    // choosed subforum 选择的子板块
    public static func getSelectSubForum(fid: Int) -> Forum? {
        let fid = UserDefaults.standard.integer(forKey: "\(key_select_subforum)_\(fid)_fid") ;
        if fid > 0 {
            let name = UserDefaults.standard.string(forKey: "\(key_select_subforum)_\(fid)_title")
            let f = Forum(fid: fid, name: name ?? "", login: false)
            return f
        }
        
        return nil
    }
    
    

    //size = 0 small 1 = middle 2 = large
    //下载并保存头像
    private static var isLoadingAvater = false

    public static func getAvater(uid: Int, size: Int = 1, callback: @escaping (Data?) -> Void) {
        let day = UserDefaults.standard.integer(forKey: "saved_avatar_time_\(uid)")
        // 缓存头像保存3天
        var d: Data?
        if Int(Date().timeIntervalSince1970 / 86400) - day < 3 {
            if let d = UserDefaults.standard.data(forKey: "\(key_avater)_\(uid)_\(size)") {
                callback(d)
                return
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try d = Data(contentsOf: Urls.getAvaterUrl(uid: uid, size: size)!)
                if d != nil {
                    setAvater(uid: uid, size: size, data: d!)
                    callback(d)
                    return
                }
            } catch {
                print(error)
            }

            callback(nil)
        }
    }

    //设置头像
    public static func setAvater(uid: Int, size: Int = 1, data: Data) {
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.set(Date().timeIntervalSince1970 / 86400, forKey: "saved_avatar_time_\(uid)")
            UserDefaults.standard.set(data, forKey: "\(key_avater)_\(uid)_\(size)")
        }
    }
    
    //设置板块列表
    //uid == nil 表示未登录
    public static func setForumlist(uid: Int?, data: Data) {
        UserDefaults.standard.set((Date().timeIntervalSince1970 / 86400), forKey: "\(key_forumlist_saved_time)_\(uid ?? 0)")
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.set(data, forKey: "\(key_forumlist)_\(uid ?? 0)")
        }
    }
    
    //板块列表的显示方式
    public static var forumListDisplayType: Int? {
        get {
            return UserDefaults.standard.integer(forKey: key_forumlist_display_type)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: key_forumlist_display_type)
        }
    }
    
    
    //网络类型设置 0--auto 1-out 2-inner
    public static var networkType: Int {
        get {
            return UserDefaults.standard.integer(forKey: key_work_type)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: key_work_type)
        }
    }
    
    //uid == nil 表示未登录
    public static func getForumlist(uid: Int?) -> Data? {
        return UserDefaults.standard.data(forKey: "\(key_forumlist)_\(uid ?? 0)")
    }
    
    
    // 板块列表保存的时间 天
    public static func getFormlistSavedTime(uid: Int?) -> Int {
        return UserDefaults.standard.integer(forKey: "\(key_forumlist_saved_time)_\(uid ?? 0)")
    }
}
