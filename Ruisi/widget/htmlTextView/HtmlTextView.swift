//
//  HtmlTextView.swift
//  HtmlTextView
//
//  Created by yang on 2017/12/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class HtmlTextView: UITextView, UITextViewDelegate {
    public static let baseURL = URL(string: Urls.baseUrl)

    var htmlViewDelegate: ((LinkClickType) -> Void)?
    var htmlText: String? {
        didSet {
            if let text = htmlText {
                attributedText = AttributeConverter(font: UIFont.systemFont(ofSize: 16), textColor: UIColor.darkText,
                        linkTextAttributes: linkTextAttributes).convert(src: text)
            } else {
                attributedText = nil
            }
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        isEditable = false
        textContainerInset = UIEdgeInsets.zero
        //textContainer.lineFragmentPadding = 0
        //layoutManager.usesFontLeading = false

        textColor = UIColor.darkText
        isScrollEnabled = false
        delegate = self

        //linkTextAttributes = []
    }


    // textview 链接点击事件
    // textView.delegate = self
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // base http://rs.xidian.edu.cn/
        // asb  http://rs.xidian.edu.cn/forum.php?mod=viewthread&tid=862167&aid=871569&from=album&page=1&mobile=2

        //http://www.baidu.com bas nil
        print("url click", URL.absoluteString)
        // 内部链接点击
        let url = URL.absoluteString
        if url.hasPrefix("http://rs.xidian.edu.cn/") || url.hasPrefix("http://rsbbs.xidian.edu.cn/") {
            if url.contains("from=album") && url.contains("aid") { //点击了图片
                if let aid = Utils.getNum(prefix: "aid=", from: url) {
                    htmlViewDelegate?(.viewAlbum(aid: aid, url: url))
                }
            } else if url.contains("forum.php?mod=viewthread&tid=") || url.contains("forum.php?mod=redirect&goto=findpost") { // 帖子
                if let tid = Utils.getNum(prefix: "tid=", from: url) {
                    htmlViewDelegate?(.viewPost(tid: tid, pid: nil))
                }
            } else if url.contains("home.php?mod=space&uid=") { // 用户
                if let uid = Utils.getNum(prefix: "uid=", from: url) {
                    htmlViewDelegate?(.viewUser(uid: uid))
                }
            } else if url.contains("forum.php?mod=post&action=newthread") {//发帖链接
                let fid = Utils.getNum(prefix: "fid=", from: url)
                htmlViewDelegate?(.newPost(fid: fid))
            } else if url.contains("member.php?mod=logging&action=login") { //登陆
                htmlViewDelegate?(.login())
            } else if url.contains("forum.php?mod=forumdisplay&fid=") { // 分区列表
                if let fid = Utils.getNum(prefix: "fid=", from: url) {
                    htmlViewDelegate?(.viewPosts(fid: fid))
                }
            } else if url.contains("forum.php?mod=post&action=reply") { // 回复
                if let tid = Utils.getNum(prefix: "tid=", from: url) {
                    let pid = Utils.getNum(prefix: "pid=", from: url)
                    htmlViewDelegate?(.reply(tid: tid, pid: pid))
                }
            } else if url.contains("forum.php?mod=attachment") { // 附件
                htmlViewDelegate?(.attachment(url: url))
            } else {
                htmlViewDelegate?(.others(url: url))
            }
        } else {
            return true
        }

        return false
    }


    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("image click", textAttachment)

        return false
    }

}
