//
//  HtmlLabel.swift
//  Ruisi
//
//  Created by yang on 2017/12/22.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 支持显示html的label
// TODO 表情占位符替换位表情
class HtmlLabel: UILabel {
    
    // 链接点击回调
    public var linkClickDelegate: ((LinkClickType) -> Void)?
    // 存储所有的链接
    private var urlRanges : [UrlItem]?
    // 存储当前点击的链接
    private var clickItem:  UrlItem?
    
    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    // text显示的区域
    private lazy var textContainer = NSTextContainer()
    
    override var attributedText: NSAttributedString? {
        didSet {
            initTextStorage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
    }
    
    override func drawText(in rect: CGRect) {
        // 画背景 设置了attributeSring的背景色才会画
        layoutManager.drawBackground(forGlyphRange: NSRange(location: 0, length: textStorage.length), at: CGPoint())
        
        // 画文字
        layoutManager.drawGlyphs(forGlyphRange: NSRange(location: 0, length: textStorage.length), at: CGPoint())
    }
    
    private func initialize() {
        textColor = UIColor.darkText
        isUserInteractionEnabled = true
        
        initTextStorage()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
    }
    
    func initTextStorage() {
        if let attrText = attributedText {
            textStorage.setAttributedString(attrText)
        } else if let text = text {
            textStorage.setAttributedString(NSAttributedString(string: text))
        } else {
            textStorage.setAttributedString(NSAttributedString(string: ""))
        }
        
        urlRanges = nil
    }
    
    func updateUrlRanges()  {
        urlRanges = [UrlItem]()
        guard let attrString = attributedText else {
            return
        }
        
        attrString.enumerateAttribute(NSAttributedString.Key.link, in: NSRange(location: 0, length: attrString.length) , options: []) { (url, range, _) in
            guard let url = url as? URL else { return }
            urlRanges?.append(UrlItem(url: url.absoluteString, range: range))
        }
        
        /*
         // 主动提取链接
         let urlPattern = "[a-zA-Z]*://[a-zA-Z0-9/\\.]*"
         if let regx = try? NSRegularExpression(pattern: urlPattern, options: []) {
         let matchs =  regx.matches(in: textStorage.string, options: [], range: NSRange(location: 0, length: textStorage.length))
         
         for m in matchs {
         print((textStorage.string as NSString).substring(with: m.range(at: 0)))
         //range m.range(at: 0)
         // str (textStorage.string as NSString).substring(with: m.range(at: 0))
         }
         }
         */
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        clickItem = nil
        guard let location =  touches.first?.location(in: self) else {
            return
        }
        
        // 在layoutManager 找到当前点击的点位置
        let index = layoutManager.glyphIndex(for: location, in: textContainer)
        if urlRanges == nil {
            updateUrlRanges()
        }
        
        for item in urlRanges ?? [] {
            if NSLocationInRange(index, item.range) {
                // 点击了链接
                clickItem = item
                //print("按下:\(item.url) \(item.range)")
                //85, 26, 139
                textStorage.addAttributes([NSAttributedString.Key.backgroundColor : UIColor(white: 0.97, alpha: 1.0)], range: item.range)
                setNeedsDisplay()
                break
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location =  touches.first?.location(in: self) else {
            return
        }
        
        // 在layoutManager 找到当前点击的点位置
        if let delegate = linkClickDelegate {
            let index = layoutManager.glyphIndex(for: location, in: textContainer)
            if let item = clickItem, NSLocationInRange(index, item.range) {
                // 抬起的链接和点击的链接是一个则表示用户点击了链接
                LinkClickHandler.handle(url: item.url.replacingOccurrences(of: "&amp;", with: "&"), delegate: delegate)
            }
        }
        
        if let item = clickItem {
            textStorage.removeAttribute(NSAttributedString.Key.backgroundColor, range: item.range)
            setNeedsDisplay()
        }
        
        clickItem = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let item = clickItem {
            textStorage.removeAttribute(NSAttributedString.Key.backgroundColor, range: item.range)
            setNeedsDisplay()
        }
        clickItem = nil
    }
}
