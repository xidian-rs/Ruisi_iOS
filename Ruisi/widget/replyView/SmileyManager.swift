//
//  SmileyManager.swift
//  SmileyView
//
//  Created by yang on 2017/12/21.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

// 表情文件管理类 单例没有从文件读入有直接返回
class SmileyManager {
    private static var privateManager: SmileyManager?
    
    public static var shared: SmileyManager {
        if privateManager == nil {
            privateManager = SmileyManager()
            
        }
        return privateManager!
    }
    
    public  var  smileys: [SmileyGroup]
    
    public func pageCount(size: Int) -> Int {
        return smileys.reduce(0, {$0 + $1.pageCount(size: size)})
    }
    
    // 根据scrollview当前的页数返回处于那个组的哪一页
    public func indexPathFor(page: Int, pageSize: Int) -> IndexPath {
        var pageBack = page
        var section = 0
        var item = 0
        for (k,v) in smileys.enumerated() {
            if pageBack <= v.pageCount(size: pageSize) - 1 {
                section = k
                item = pageBack
                break
            }else {
                pageBack -= v.pageCount(size: pageSize)
            }
        }
        
        return IndexPath(item: item, section: section)
    }
    
    private init() {
        // 读文件
        let filePath = Bundle.main.path(forResource: "assets/smiley", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath, isDirectory: false))
        let decoder = JSONDecoder()
        smileys = try! decoder.decode([SmileyGroup].self, from: data)
    }
}

class SmileyGroup: Codable {
    public var smileys: [SmileyItem]
    public var name: String
    public var isImage = true
    
    public func pageCount(size: Int) -> Int {
        return (smileys.count - 1) / size + 1
    }
    
    public func getSmileys(page: Int, pageSize: Int) -> [SmileyItem] {
        var max = (page + 1) * pageSize
        if max > smileys.count {
            max = smileys.count
        }
        let min = page * pageSize
        
        
        return Array(smileys[min..<max])
    }
}

class SmileyItem: Codable {
    public var path: String? // 图片表情路机构
    public var name: String? // 表情的名字
    public var value: String //发送给服务器的字符串 文字表情就是此
    
    public var image: UIImage? {
        if let path = self.path {
            let path = Bundle.main.path(forResource: "assets/smiley/\(path)", ofType: "png")!
            return UIImage(contentsOfFile: path)
        }
        
        return nil
    }
    
    public func imageText(font: UIFont) -> NSAttributedString {
        guard let image = image else { return NSAttributedString(string: "")}
        
        let attach =  ImageAttachment()
        attach.value = value
        attach.image = image
        attach.bounds = CGRect(x: 0, y: -2, width: font.lineHeight, height: font.lineHeight)
        
        let attrStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attach))
        
        //添加font属性防止字体变小
        attrStr.addAttributes([NSAttributedStringKey.font: font],
                              range: NSRange(location: 0, length: 1))
        return attrStr
    }
}
