//
// Created by yang on 2017/6/29.
// Copyright (c) 2017 yang. All rights reserved.
//

import Foundation
import UIKit

class AtrributeConveter: HtmlParserDelegate {
    //NSFontAttributeName               UIFont
    //NSForegroundColorAttributeNam     UIColor
    //NSBackgroundColorAttributeName
    //NSLigatureAttributeName           0/1     连字符
    //NSKernAttributeName               -/+     设定字符间距，正值间距加宽，负值间距变窄
    //NSStrikethroughStyleAttributeName NSUnderlineStyle  删除线
    //NSStrikethroughColorAttributeName  设置删除线颜色，
    //NSUnderlineStyleAttributeName      设置下划线，取值为 NSNumber 对象（整数），枚举常量 NSUnderlineStyle中的值，与删除线类似
    //NSUnderlineColorAttributeName      设置下划线颜色
    //NSStrokeWidthAttributeName         设置笔画宽度，取值为 NSNumber 对象（整数），负值填充效果，正值中空效果
    //NSStrokeColorAttributeName         填充部分颜色，不是字体颜色，取值为 UIColor 对象
    //NSShadowAttributeName              设置阴影属性，取值为 NSShadow 对象
    //NSTextEffectAttributeName          设置文本特殊效果，取值为 NSString 对象，目前只有图版印刷效果可用：
    //NSBaselineOffsetAttributeName      设置基线偏移值，取值为 NSNumber （float）,正值上偏，负值下偏
    //NSObliquenessAttributeName         设置字形倾斜度，取值为 NSNumber （float）,正值右倾，负值左倾
    //NSExpansionAttributeName           设置文本横向拉伸属性，取值为 NSNumber （float）,正值横向拉伸文本，负值横向压缩文本
    //NSWritingDirectionAttributeName    设置文字书写方向，从左向右书写或者从右向左书写
    //NSVerticalGlyphFormAttributeName   设置文字排版方向，取值为 NSNumber 对象(整数)，0 表示横排文本，1 表示竖排文本
    //NSLinkAttributeName                设置链接属性，点击后调用浏览器打开指定URL地址
    //NSAttachmentAttributeName          设置文本附件,取值为NSTextAttachment对象,常用于文字图片混排
    //NSParagraphStyleAttributeName      设置文本段落排版格式，取值为 NSParagraphStyle 对象
    
    
    private var linkTextAttributes: [String: Any]?
    private var font: UIFont!
    private var textColor: UIColor!
    
    // html标签栈
    private var nodes: [HtmlNode]
    private var attributedString: NSMutableAttributedString
    
    private var position: Int {
        get {
            return attributedString.length
        }
    }
    
    init(font: UIFont, textColor: UIColor, linkTextAttributes: [String: Any]? = nil) {
        self.font = font
        self.textColor = textColor
        self.linkTextAttributes = linkTextAttributes
        attributedString = NSMutableAttributedString()
        nodes = [HtmlNode]()
    }
    
    func convert(src: String) -> NSAttributedString {
        HtmlParser(src: src, delegate: self).parse()
        return attributedString
    }
    
    // MARK: - HtmlParserDelegate
    func start() {
        //print("===start of html===")
    }
    
    func startNode(node: HtmlNode) {
        //print("<\(node.name)>")
        if node.type.isBlock() {
            handleBlockTag()
        }
        
        switch node.type {
        case .UNKNOWN:
            break;
        case .BR:
            handleBlockTag()
        case .IMG: // 图片标签留着最后处理不然有可能会被替换
            //node.start = position
            //node.end = node.start
            //nodes.append(node)
            handleImg(start: position, attr: node.attr)
        case .HR:
            break
        default:
            node.start = position
            nodes.append(node)
        }
    }
    
    func characters(text: String) {
        //print(text)
        attributedString.append(NSAttributedString(string: text))
        //还要根据栈顶的元素类型添加适当的\n
    }
    
    func endNode(type: HtmlTag, name: String) {
        //print("</\(name)>")
        if type == .UNKNOWN || type == .BR || type == .IMG
            || type == .HR || nodes.isEmpty {
            return
        }
        
        if nodes.last?.type != type { return }
        //let node = nodes.popLast()!
        let startNode = nodes.last!
        let endNode =  HtmlNode(type: type, name: name, attr: startNode.attr)
        endNode.start = startNode.start
        
        if endNode.type.isBlock() {
            handleBlockTag()
        }
        
        //var start = startNode.start
        startNode.end = position
        endNode.end = position
        nodes.append(endNode)
    }
    
    func end() {
        //print("===end of html===")
        while let endNode = nodes.popLast() {
            var startNode: HtmlNode? = nil
            for (i,v) in nodes.enumerated() {
                if v.start == endNode.start && v.end == endNode.end && v.type == endNode.type {
                    startNode = v
                    nodes.remove(at: i)
                    break
                }
            }
            
            if startNode == nil { continue }
            
            var start = endNode.start
            let end = endNode.end
            let attr = startNode!.attr
            
            switch (endNode.type) {
            //discuz 没有h标签
            case .DIV:
                // todo 会覆盖表情 待解决
                break
            case .B,.STRONG:
                addAttrs([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: font.pointSize)], start: start, end: end)
            case .P:
                handleParagraph(start: start, attr: attr)
            case .A:
                if let url = attr?.href {
                    let uu: URL?
                    if !url.starts(with: "http") {
                        uu = URL(string: url, relativeTo: HtmlTextView.baseURL)
                    }else {
                        uu = URL(string: url)
                    }
                    
                    if let u = uu {
                        if start > 0 {
                            // 链接不包括回车 空格
                            var index = attributedString.string.index(attributedString.string.startIndex, offsetBy: start)
                            while index < attributedString.string.endIndex, attributedString.string[index] == "\n" {
                                index = attributedString.string.index(after: index)
                                start += 1
                            }
                        }
                        addAttrs([NSAttributedStringKey.link: u, NSAttributedStringKey.font:font], start: start, end: end)
                    }
                }
                break
            case .I, .EM, .CITE, .DFN: // 倾斜 darkGray
                addAttrs([NSAttributedStringKey.obliqueness: 0.15, NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font:font], start: start, end: end)
            case .DEL, .S, .STRIKE: // 删除线
                addAttrs([NSAttributedStringKey.strikethroughStyle: 1,NSAttributedStringKey.font:font], start: start, end: end)
            case .U, .INS: // 下划线
                addAttrs([NSAttributedStringKey.underlineStyle: 1, NSAttributedStringKey.font:font], start: start, end: end)
            case .LI:
                //setSpan(start, new Li());
                break;
            case .PRE ,.BLOCKQUOTE: // darkGray 0.9fontSize
                addAttrs([NSAttributedStringKey.foregroundColor: UIColor.darkGray,
                          NSAttributedStringKey.font: UIFont.systemFont(ofSize: font.pointSize * 0.9)], start: start, end: end)
            case .Q, .CODE, .KBD:
                //等宽 字体
                addAttrs([NSAttributedStringKey.backgroundColor: UIColor(white: 0.97, alpha: 1),NSAttributedStringKey.font:font], start: start, end: end)
            case .FONT:
                if let color = attr?.color {
                    addAttrs([NSAttributedStringKey.foregroundColor: color, NSAttributedStringKey.font:font], start: start, end: end)
                }
                
                if let bgColor = attr?.bgColor {
                    addAttrs([NSAttributedStringKey.backgroundColor: bgColor, NSAttributedStringKey.font:font], start: start, end: end)
                }
                /* // TODO 会使布局变乱
                 if let size = attr?.size { //dz 默认字体大概在2.5左右 1-7
                 let fontSize: CGFloat
                 if size == 1 { fontSize = font.pointSize - 1 }
                 else if size == 2 || size == 3 { fontSize = font.pointSize}
                 else if size == 4 || size == 5 { fontSize = font.pointSize + 1.5 }
                 else { fontSize = font.pointSize + 3 }
                 addAttrs([NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize)], start: start, end: end)
                 }*/
            case .BIG:
                addAttrs([NSAttributedStringKey.font: UIFont.systemFont(ofSize: font.pointSize  * 1.1)], start: start, end: end)
            case .SMALL:
                addAttrs([NSAttributedStringKey.font: UIFont.systemFont(ofSize: font.pointSize * 0.9)], start: start, end: end)
            default:
                break
            }
        }
        
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineHeightMultiple = CGFloat(1.5)
        addAttrs([NSAttributedStringKey.paragraphStyle : paraStyle, NSAttributedStringKey.font: font], start: 0, end: position)
    }
    
    //div ul 等块状标签
    //主要是添加回车
    private var lastignore = false
    private func handleBlockTag() { // 适当减少连续br的数目
        if attributedString.length == 0 { return }
        if lastignore {
            attributedString.append(NSAttributedString(string: "\n"))
            lastignore = false
        }else if let item = attributedString.string.last, item != "\n" {
            lastignore = false
            attributedString.append(NSAttributedString(string: "\n"))
        }else {
            lastignore = true
        }
    }
    
    
    // 添加属性
    private func addAttrs(_ attrs: [NSAttributedStringKey: Any], start: Int, end: Int) {
        if start >= end { return }
        attributedString.addAttributes(attrs, range: NSMakeRange(start, end - start))
    }
    
    // 段落处理
    func handleParagraph(start: Int,attr:HtmlAttr?) {
        if let textAlign = attr?.textAlign {
            let style = NSMutableParagraphStyle()
            style.alignment = textAlign
            addAttrs([NSAttributedStringKey.paragraphStyle:style], start: start, end: position)
        }
    }
    
    //处理图片 true -> 代表之后hai yao chu li
    func handleImg(start:Int, attr: HtmlAttr?) {
        if let src = attr?.src {
            if src.starts(with: "static/image/smiley") {
                if let image =  ImageGetter.getSmiley(src: src, start: start, excute: { (downloadedImage) in
                    if let _ = downloadedImage {
                        //TODO 表情下载好了
                    }
                }) {
                    let attach = NSTextAttachment()
                    attach.image = image
                    attach.bounds = CGRect(x: 0, y: -2, width: self.font.pointSize + 3 , height: self.font.pointSize + 3)
                    let attrStringWithImage = NSAttributedString(attachment: attach)
                    self.attributedString.insert(attrStringWithImage, at: start)
                }
            }else {
                //attributes: [NSLinkAttributeName:URL(string: attr?.src ?? "", relativeTo: baseURL) ?? baseURL as Any]
                let img = NSAttributedString(string: " [图片] ")
                attributedString.append(img)
            }
        }
    }
}
