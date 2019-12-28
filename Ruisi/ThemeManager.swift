//
//  ThemeManager.swift
//  Ruisi
//
//  Created by yang on 2017/12/14.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

// 主题管理类
// 返回一些常见的颜色
// currentPrimaryColor 当前主色调
// currentTitleColor 当前字体颜色
// TODO 支持更多实现夜间模式
// bg,...
class ThemeManager {
    private static var themeBackUp: Theme?
    
    public static let colors: [UIColor] = [
        UIColor.systemRed, parseHexColor(0x1e1e1e), parseHexColor(0xf44836), UIColor.systemOrange, UIColor.systemGreen, parseHexColor(0x16c24b),
        UIColor.systemTeal, parseHexColor(0x2b86e3), UIColor.blue, UIColor.purple, parseHexColor(0xcc268f), parseHexColor(0x39c5bb)]

    public static let names = [
        "默认", "黑色", "橘红", "橘黄", "原谅", "翠绿",
        "青色", "天蓝", "蓝色", "紫色", "紫红", "初音"]

    public static var themes: [Theme] {
        get {
            var ts = [Theme]()
            for i in 0..<ThemeManager.colors.count {
                ts.append(Theme(id: i, name: ThemeManager.names[i], titleColor: UIColor.white, primaryColor: ThemeManager.colors[i]))
            }
            return ts
        }
    }

    public static func initTheme() {
        let theme = ThemeManager.currentTheme
        print("====================")
        print("init theme:\(theme.name)")
        //状态栏颜色
        UIApplication.shared.statusBarStyle = .lightContent

        //设置导航栏颜色
        let textAttributes = [NSAttributedString.Key.foregroundColor: theme.titleColor]
        UINavigationBar.appearance().titleTextAttributes = textAttributes //标题颜色
        UINavigationBar.appearance().tintColor = theme.titleColor //按钮颜色
        UINavigationBar.appearance().barTintColor = theme.primaryColor //背景色
        
        //设置tabBar颜色
        UITabBar.appearance().tintColor = theme.primaryColor

        //设置toolbar颜色
        UIToolbar.appearance().tintColor = UIColor.darkGray
    }

    public static var currentTheme: Theme {
        get {
            if ThemeManager.themeBackUp == nil {
                ThemeManager.themeBackUp = Theme(id: Settings.currentTheme, name: names[Settings.currentTheme], titleColor: UIColor.white,
                        primaryColor: colors[Settings.currentTheme])
            }
            return ThemeManager.themeBackUp!
        }
    }

    public static var currentPrimaryColor: UIColor {
        return currentTheme.primaryColor
    }
    public static var currentTitleColor: UIColor {
        return currentTheme.titleColor
    }

    public static var currentThemeId: Int {
        get {
            return currentTheme.id
        }
        set {
            if Settings.currentTheme != newValue {
                ThemeManager.themeBackUp = nil
                Settings.currentTheme = newValue
                NotificationCenter.default.post(name: .themeChanged, object: self)
                initTheme()
            }
        }
    }

    private static func parseHexColor(_ color: Int) -> UIColor {
        return UIColor(red: CGFloat(((color & 0xff0000) >> 16)) / CGFloat(255),
                green: CGFloat(((color & 0x00ff00) >> 8)) / CGFloat(255), blue: CGFloat(color & 0x0000ff) / CGFloat(255), alpha: 1.0)
    }
}

extension Notification.Name {
    static let themeChanged = Notification.Name("ThemeChanged")
}

struct Theme {
    var id: Int
    var titleColor: UIColor
    var primaryColor: UIColor
    var name: String

    init(id: Int, name: String, titleColor: UIColor, primaryColor: UIColor) {
        self.id = id
        self.name = name
        self.titleColor = titleColor
        self.primaryColor = primaryColor
    }
}
