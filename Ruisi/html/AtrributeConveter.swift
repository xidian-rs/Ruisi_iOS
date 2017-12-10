//
// Created by yang on 2017/6/29.
// Copyright (c) 2017 xidian. All rights reserved.
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
    
    let fontSize: CGFloat = 18
    let baseURL = URL(string: Urls.baseUrl)
    let linkColor = UIColor.blue
    var nodes: [HtmlNode]
    
    var attributedString: NSMutableAttributedString
    var position: Int {
        get {
            return attributedString.length
        }
    }
    
    init() {
        attributedString = NSMutableAttributedString()
        nodes = [HtmlNode]()
    }
    
    func convert(src: String) -> NSAttributedString {
        HtmlParser(src: src, delegate: self).parse()
        
        attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: fontSize), range: NSMakeRange(0, position))
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineHeightMultiple = CGFloat(1.2)
        attributedString.addAttribute(NSAttributedStringKey.paragraphStyle,value: paraStyle,range: NSMakeRange(0, position))
        return attributedString
    }
    
    
    func start() {
        //print("start")
    }
    
    func startNode(node: HtmlNode) {
        //print("<\(node.name)>  \(node.type)")
        if node.type.isBlock() {
            handleBlockTag()
        }
        switch node.type {
        case .UNKNOWN:
            break;
        case .BR:
            handleBlockTag()
        case .IMG:
            handleImg(start: position, attr: node.attr)
        case .HR:
            break
        default:
            node.start = position
            nodes.append(node)
        }
    }
    
    func characters(text: String) {
        attributedString.append(NSAttributedString(string: text))
        //还要根据栈顶的元素类型添加适当的\n
    }
    
    func endNode(type: HtmlTag, name: String) {
        //print("</\(name)>  \(type)")
        if type == .UNKNOWN || type == .BR || type == .IMG
            || type == .HR || nodes.isEmpty {
            return
        }
        
        if nodes.last?.type != type {
            return
        }
        
        let node = nodes.popLast()
        var start = node!.start
        
        switch (type) {
        //discuz 没有h标签
        case .DIV:
            // todo 会覆盖表情 待解决
            break
        case .B,.STRONG,.H1, .H2, .H3, .H4, .H5, .H6:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue):UIFont.boldSystemFont(ofSize: fontSize)], start: start)
        case .P:
            handleParagraph(start: start, attr: node?.attr)
        case .A:
            if start > 0  {
                var index = attributedString.string.index(attributedString.string.startIndex, offsetBy: start)
                while index < attributedString.string.endIndex, attributedString.string[index] == "\n" {
                    index = attributedString.string.index(after: index)
                    start += 1
                }
            }
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.link.rawValue): URL(string: node!.attr?.href ?? "", relativeTo: baseURL) ?? baseURL as Any], start: start)
            break
        case .I, .EM, .CITE, .DFN:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.obliqueness.rawValue):0.3], start: start)
        case .DEL, .S, .STRIKE:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.strikethroughStyle.rawValue): 1], start: start)
        case .U, .INS:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.underlineStyle.rawValue): 1], start: start)
        case .LI:
            //setSpan(start, new Li());
            break;
        case .PRE ,.BLOCKQUOTE:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): UIColor.darkGray], start: start)
        case .Q, .CODE, .KBD:
            //等宽 字体
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.backgroundColor.rawValue): UIColor(white: 0.96, alpha: 1)], start: start)
        case .FONT:
            if let color = node?.attr?.color {
                addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): color], start: start)
            }
            
            if let bgColor = node?.attr?.bgColor {
                addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.backgroundColor.rawValue): bgColor], start: start)
            }
        case .BIG:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue): UIFont.systemFont(ofSize: CGFloat(fontSize  * 1.2))], start: start)
        case .SMALL:
            addAttrs(attrs: [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue): UIFont.systemFont(ofSize: CGFloat(fontSize * 0.8))], start: start)
        default:
            break
        }
        
        if type.isBlock() {
            handleBlockTag()
        }
    }
    
    func end() {
        //print("end")
    }
    
    //div ul 等块状标签
    //主要是添加回车
    private func handleBlockTag() {
        if position <= 1 {
            return
        }
        let c = attributedString.string.last!
        if c != "\n" {
            attributedString.append(NSAttributedString(string: "\n"))
        }
    }
    
    
    // 添加属性
    private func addAttrs(attrs: [NSAttributedStringKey: Any], start: Int) {
        if start >= position {
            return
        }
        attributedString.setAttributes(attrs,
                                       range: NSMakeRange(start, position - start))
    }
    
    // 段落处理
    func handleParagraph(start: Int,attr:HtmlAttr?) {
        if let textAlign = attr?.textAlign {
            let style = NSMutableParagraphStyle()
            style.alignment = textAlign
            attributedString.addAttributes([NSAttributedStringKey.paragraphStyle:style],range: NSMakeRange(0, position))
        }
    }
    
    //处理图片
    func handleImg(start:Int, attr: HtmlAttr?) {
        if let src = attr?.src {
            if src.starts(with: "static/image/smiley") {
                ImageGetter.getSmiley(src: src, start: start, excute: { (image) in
                    if let i = image {
                        let attach = NSTextAttachment()
                        attach.image = i
                        attach.bounds = CGRect(x: 0, y: -6, width: 28, height: 28)
                        let attrStringWithImage = NSAttributedString(attachment: attach)
                        self.attributedString.append(attrStringWithImage)
                    }
                })
            }else {
                let img = NSAttributedString(string: " [图片] ")
                attributedString.append(img)
            }
//            //static/image/smiley
//            let range = src.range(of: "static/image/smiley")
//            //表情
//            if range?.lowerBound ==  src.startIndex {
//                let name = "tb001"
//                let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "assets/smiley/tieba")!
//                let attach = NSTextAttachment()
//                attach.image = UIImage(contentsOfFile: path)
//                attach.bounds = CGRect(x: 0, y: -6, width: 28, height: 28)
//                let attrStringWithImage = NSAttributedString(attachment: attach)
//                attributedString.append(attrStringWithImage)
//                return
//            }
        }
        
        //attributes: [NSLinkAttributeName:URL(string: attr?.src ?? "", relativeTo: baseURL) ?? baseURL as Any]
    }
}
