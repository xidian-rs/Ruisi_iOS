//
// Created by yang on 2017/6/29.
// Copyright (c) 2017 yang. All rights reserved.
//

import Foundation
import UIKit

// HTML -> AttributeString
class AttributeConverter: HtmlParserDelegate {
    
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
    
    private var font: UIFont!
    private var textColor: UIColor!
    private var linkTextClor = UIColor(red: 0, green: CGFloat(122) / 255, blue: 1.0, alpha: 1.0)
    
    // html标签栈
    private var nodes: [HtmlNode]
    private var attributedString: NSMutableAttributedString
    
    private var position: Int {
        get {
            return attributedString.length
        }
    }
    

    init(font: UIFont, textColor: UIColor) {
        self.font = font
        self.textColor = textColor
        
        attributedString = NSMutableAttributedString()
        nodes = [HtmlNode]()
    }
    
    func convert(src: String) -> NSAttributedString {
        HtmlParser(src: src, delegate: self).parse()
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineHeightMultiple = CGFloat(1.5)

        addAttrs([NSAttributedStringKey.paragraphStyle: paraStyle], start: 0, end: position)
        addAttrs([NSAttributedStringKey.font: font], start: 0, end: position)
        return attributedString
    }
    
    // MARK: - HtmlParserDelegate
    func start() {
        // print("===start of html===")
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
            handleImg(start: position, attr: node.attr)
        case .HR:
            break
        default:
            node.start = position
            if node.type == .LI {
                attributedString.append(NSAttributedString(string: " · "))
            }
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
        
        if nodes.last?.type != type {
            if type.isBlock() {
                handleBlockTag()
            }
            return
        }
        //let node = nodes.popLast()!
        let startNode = nodes.last!
        let endNode = HtmlNode(type: type, name: name, attr: startNode.attr)
        endNode.start = startNode.start
        
        appendCount = 0
        if endNode.type.isBlock() {
            handleBlockTag()
        } else if endNode.type == .A && position - startNode.start > 0 {
            //A标签加一个空格
            attributedString.append(NSAttributedString(string: " "))
            appendCount = 1
        }
        
        //var start = startNode.start
        startNode.end = position - appendCount
        endNode.end = position - appendCount
        nodes.append(endNode)
    }
    
    func end() {
        //print("===end of html===")
        
        // 移除内容结尾的\n
        while attributedString.length > 0 {
            let len = attributedString.length
            let lastCharRange = NSRange(location: len - 1, length: 1)
            let lastChar = attributedString.attributedSubstring(from: lastCharRange).string
            if lastChar == "\n" {
                attributedString.deleteCharacters(in: lastCharRange)
                continue
            }
            break
        }
        

        while let endNode = nodes.popLast() {
            var startNode: HtmlNode? = nil
            for (i, v) in nodes.enumerated() {
                if v.start == endNode.start && v.end == endNode.end && v.type == endNode.type {
                    startNode = v
                    nodes.remove(at: i)
                    break
                }
            }
            
            if startNode == nil {
                continue
            }
            
            var start = endNode.start
            let end = min(endNode.end, position)
            let attr = startNode!.attr
            
            switch (endNode.type) {
            //discuz 没有h标签
            case .DIV:
                // todo 会覆盖表情 待解决
                break
            case .B, .STRONG:
                //addAttrs([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: font.pointSize)], start: start, end: end)
                addAttrs([NSAttributedStringKey.foregroundColor: UIColor.black], start: start, end: end)
            case .P:
                handleParagraph(start: start, attr: attr)
            case .A:
                if let url = attr?.href {
                    let uu: URL?
                    if !url.starts(with: "http") {
                        uu = URL(string: url, relativeTo: HtmlTextView.baseURL)
                    } else {
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
                        addAttrs([NSAttributedStringKey.link: u,NSAttributedStringKey.foregroundColor: linkTextClor], start: start, end: end)
                    }
                }
                break
            case .I, .EM, .CITE, .DFN: // 倾斜 darkGray
                addAttrs([NSAttributedStringKey.obliqueness: 0.15, NSAttributedStringKey.foregroundColor: UIColor.darkGray], start: start, end: end)
            case .DEL, .S, .STRIKE: // 删除线
                addAttrs([NSAttributedStringKey.strikethroughStyle: 1], start: start, end: end)
            case .U, .INS: // 下划线
                addAttrs([NSAttributedStringKey.underlineStyle: 1], start: start, end: end)
            case .LI:
                //setSpan(start, new Li());
                break;
            case .PRE, .BLOCKQUOTE: // darkGray 0.9fontSize
                addAttrs([NSAttributedStringKey.foregroundColor: UIColor.darkGray,/*,NSAttributedStringKey.font: UIFont.systemFont(ofSize: font.pointSize - 0.5) */], start: start, end: end)
            case .Q, .CODE, .KBD:
                //等宽 字体
                addAttrs([NSAttributedStringKey.backgroundColor: UIColor(white: 0.97, alpha: 1)], start: start, end: end)
            case .FONT:
                if let color = attr?.color {
                    addAttrs([NSAttributedStringKey.foregroundColor: color], start: start, end: end)
                }
                
                if let bgColor = attr?.bgColor {
                    addAttrs([NSAttributedStringKey.backgroundColor: bgColor], start: start, end: end)
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
                break
            //addAttrs([NSAttributedStringKey.font: UIFont.systemFont(ofSize: font.pointSize * 1.1)], start: start, end: end)
            case .SMALL:
                break
            //addAttrs([NSAttributedStringKey.font: UIFont.systemFont(ofSize: font.pointSize * 0.9)], start: start, end: end)
            default:
                break
            }
            
            if startNode!.type.isBlock() {
                handleBlockTag()
            }
        }
    }
    
    //div ul 等块状标签
    //主要是添加回车
    private var lastignore = false
    private var appendCount = 0 //添加的字符
    
    private func handleBlockTag() { // 适当减少连续br的数目
        if attributedString.length == 0 {
            return
        }
        if lastignore {
            attributedString.append(NSAttributedString(string: "\n"))
            appendCount += 1
            lastignore = false
        } else if let item = attributedString.string.last, item != "\n" {
            lastignore = false
            attributedString.append(NSAttributedString(string: "\n"))
            appendCount += 1
        } else {
            lastignore = true
        }
    }
    
    
    // 段落处理
    func handleParagraph(start: Int, attr: HtmlAttr?) {
        if let textAlign = attr?.textAlign {
            let style = NSMutableParagraphStyle()
            style.alignment = textAlign
            addAttrs([NSAttributedStringKey.paragraphStyle: style], start: start, end: position)
        }
    }
    
    //处理图片 true -> 代表之后hai yao chu li
    func handleImg(start: Int, attr: HtmlAttr?) {
        if let src = attr?.src {
            if let range =  src.range(of: "static/image/smiley/") { //http://rs.xidian.edu.cn/static/image/smiley/tieba/tb025.png
                let imageSrc =  src[range.lowerBound...] //  static/image/smiley/tieba/tb025.png
                if let image = ImageGetter.getSmiley(src: String(imageSrc), start: start, excute: { (downloadedImage) in
                    if let _ = downloadedImage {
                        //TODO 表情下载好了
                    }
                }) {
                    let attach = NSTextAttachment()
                    attach.image = image
                    attach.bounds = CGRect(x: 0, y: -3, width: self.font.lineHeight, height: self.font.lineHeight)
                    let attrStringWithImage = NSAttributedString(attachment: attach)
                    self.attributedString.insert(attrStringWithImage, at: start)
                }
            } else {
                //attributes: [NSLinkAttributeName:URL(string: attr?.src ?? "", relativeTo: baseURL) ?? baseURL as Any]
                let img = NSAttributedString(string: " [图片] ")
                attributedString.append(img)
            }
        }
    }
    
    // 添加属性
    private func addAttrs(_ attrs: [NSAttributedStringKey: Any], start: Int, end: Int) {
        if start >= end {
            return
        }
        attributedString.addAttributes(attrs, range: NSMakeRange(start, min(end, attributedString.length) - start))
    }
}
