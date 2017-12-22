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
    
    private var userinfo: [AnyHashable : Any]?
    
    public var defaultPlaceholder: String?
    private var placeholder: String? {
        didSet{
            // TODO
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
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        view.frame = self.bounds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("SimpleReplyView")
        
        progressView.hidesWhenStopped = true
        contentView.delegate = self
        
        setUpTextView()
    }
    
    
    public func onSubmitClick(execute closure: @escaping (_ text: String,_ userinfo: [AnyHashable : Any]?) -> Void) {
        submitClick = closure
    }
    
    private var submitClick: ((_ text: String,_ userinfo: [AnyHashable : Any]?)->())?
    
    @IBAction func sendBtnClick(_ sender: UIButton) {
        if let text = contentView.result {
            submitClick?(text, userinfo)
        }
    }
    
    @IBAction func smileyBtnClick(_ sender: UIButton) {
        contentView.toggleEmojiInput()
    }
    
    // 主动显示回复框 并获取焦点 userinfo 用来传递数据 clear是否清除
    public func showReplyBox(clear: Bool, placeholder: String? = nil, userinfo: [AnyHashable : Any]? = nil) {
        self.userinfo = userinfo
        self.placeholder = placeholder
        self.contentView.resignFirstResponder()
        if clear {
            clearText(hide: false)
        }
    }
    

    @objc override func keyboardWillBeHidden(notification: NSNotification) {
        super.keyboardWillBeHidden(notification: notification)
        
        if contentView.text.count == 0 {
            //TODO 设置默认的placeholder
        }
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
        let color = UIColor(white: 0.95, alpha: 1.0)
        contentView.layer.borderColor = color.cgColor
        contentView.layer.borderWidth = 1.0
        contentView.layer.cornerRadius = 3.0
        //contentView.backgroundColor = UIColor(white: 0.99, alpha: 1.0)
        
        sendBtn.isEnabled = false
        sendBtn.backgroundColor = UIColor(white: 0.70, alpha: 1.0)
    }
}
