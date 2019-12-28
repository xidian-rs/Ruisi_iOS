//
//  SimpleReplyView.swift
//  Ruisi
//
//  Created by yang on 2017/12/21.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit


class SimpleReplyView: AboveKeyboardView {
    
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var smileyBtn: UIButton!
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    @IBOutlet weak var contentView: RitchTextView!

    // 占位符
    public var placeholder: String? {
        didSet{
            contentView.placeholder = placeholder
        }
    }
    
    public var isSending: Bool {
        set {
            if newValue != progressView.isAnimating {
                if newValue { // sending
                    progressView.startAnimating()
                } else { //send success
                    progressView.stopAnimating()
                }
            }
        }
        
        get {
            return progressView.isAnimating
        }
    }
    
    // 是否可以显示小尾巴
    // 要显示尾巴需要允许+用户在设置中开启
    public var enableTail = false
    
    // 小的字数限制
    // 默认不满足字数限制补空格
    public var minTextLen = 1
    
    
    class func simpleReplyView(frame: CGRect) -> SimpleReplyView {
        let nib = UINib(nibName: "SimpleReplyView", bundle: nil)
        let v = nib.instantiate(withOwner: self, options: nil).first as! SimpleReplyView
        v.frame  = frame
        return v
    }
    
    // 从storyboard加载
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let view =  Bundle.main.loadNibNamed("SimpleReplyView", owner: self, options: nil)![0] as! UIView
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
        view.frame = self.bounds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("SimpleReplyView")
        
        progressView.hidesWhenStopped = true
        contentView.delegate = self
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        
        setUpTextView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        saveAeraBottom = UIScreen.main.bounds.maxY - frame.maxY
        print("saveAeraBottom:\(saveAeraBottom)")
    }
    
    
    public func onSubmitClick(execute closure: @escaping (_ text: String) -> Void) {
        submitClick = closure
    }
    
    private var submitClick: ((_ text: String)->())?
    
    
    @IBAction func sendBtnClick(_ sender: UIButton) {
        if var text = contentView.result {
            if enableTail, Settings.enableTail, let tail = Settings.tailContent, tail.count > 0 {
                text = text + "     " + tail
            }
            
            let len = minTextLen - text.count
            if len > 0 {
                for _ in 0..<len {
                    text += " "
                }
            }
            
            submitClick?(text)
        }
    }
    
    @IBAction func smileyBtnClick(_ sender: UIButton) {
        if contentView.isEditable {
            contentView.toggleEmojiInput()
        }
    }
    
    // 主动显示回复框 并获取焦点 userinfo 用来传递数据 clear是否清除
    public func showReplyBox(clear: Bool, placeholder: String? = nil) {
        self.contentView.becomeFirstResponder()
        if clear {
            clearText(hide: false)
        }
    }
    
    private var didClickAt: ((_ textView: UITextView, _ haveAt: Bool) -> Void)?
    
    public func onAtClick(execute closure: @escaping (_ textView: UITextView, _ haveAt: Bool) -> Void) {
        didClickAt = closure
    }
}

extension SimpleReplyView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if contentView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0 {
            sendBtn.isEnabled = true
            sendBtn.backgroundColor = ThemeManager.currentPrimaryColor
        } else {
            sendBtn.isEnabled = false
            sendBtn.backgroundColor = UIColor(white: 0.70, alpha: 1.0)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "@" {
            didClickAt?(textView, true)
        }
        
        return true
    }
    
    func hidekeyboard() {
        contentView.resignFirstResponder()
    }
    
    // 清除内容 hide参数是否需要隐藏键盘
    func clearText(hide: Bool)  {
        sendBtn.isEnabled = false
        sendBtn.backgroundColor = UIColor(white: 0.70, alpha: 1.0)
        contentView.text = nil
        contentView.attributedText = nil
        if hide {
            contentView.resignFirstResponder()
        }
    }
    
    func setUpTextView() {
        //let color = UIColor(white: 0.95, alpha: 1.0)
        //contentView.layer.borderColor = color.cgColor
        //contentView.layer.borderWidth = 1.0
        contentView.layer.cornerRadius = 3.0
        //contentView.backgroundColor = UIColor(white: 0.99, alpha: 1.0)
        
        sendBtn.isEnabled = false
        sendBtn.backgroundColor = UIColor(white: 0.70, alpha: 1.0)
    }
}
