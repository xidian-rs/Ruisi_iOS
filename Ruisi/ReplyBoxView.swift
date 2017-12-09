//
//  ReplyBoaxView.swift
//  Ruisi
//
//  Created by yang on 2017/12/6.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ReplyBoxView: /*AboveKeyboardView*/UIView {
    var contentView : UIView!
    var placeholderLabel: UILabel!
    var inputBox:UITextView!
    var clsoeBtn:UIButton!
    var sendBtn:UIButton!
    var showTailCheckBox:LTHRadioButton!
    var loadingIndicate:UIActivityIndicatorView!
    var context:UIViewController?
    var isLz = true
    var pos = 0
    
    private var didSubmitCallback: (_ content:String?,_ isLz:Bool,_ pos:Int) -> Void = { _,_,_  in }
    
    private var didCloseCallback: () -> Void = { }
    
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        print("========awakeFromNib")
        xibSetup()
    }
    
    public func onSubmit(execute closure: @escaping (_ content:String?,_ isLz: Bool,_ pos:Int) -> Void) {
        didSubmitCallback = closure
    }
    
    public func onClose(execute closure: @escaping () -> Void) {
        didCloseCallback = closure
    }
    
    
    func xibSetup() {
        print("\(type(of: self))")
        contentView = loadViewFromNib()
        placeholderLabel = contentView.viewWithTag(1) as! UILabel
        inputBox = contentView.viewWithTag(2) as! UITextView
        showTailCheckBox = contentView.viewWithTag(3) as! LTHRadioButton
        clsoeBtn = contentView.viewWithTag(4) as! UIButton
        sendBtn = contentView.viewWithTag(5) as! UIButton
        loadingIndicate = contentView.viewWithTag(6) as! UIActivityIndicatorView
        
        let setTailBtn = contentView.viewWithTag(7) as! UIButton
        setTailBtn.addTarget(self, action: #selector(toSettingClick), for: .touchUpInside)
        
        contentView.frame = bounds
        
        // Make the view stretch with containing view
        contentView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(contentView)
        
        clsoeBtn.addTarget(self, action: #selector(closeClick(_:)), for: .touchUpInside)
        sendBtn.addTarget(self, action: #selector(submitClick(_:)), for: .touchUpInside)
        
        if Settings.enableTail {
            showTailCheckBox.select()
        }
        
        showTailCheckBox.onSelect {
            print("I'm selected.")
            Settings.enableTail = true
        }
        
        showTailCheckBox.onDeselect {
            print("I'm deselected.")
            Settings.enableTail = false
        }
    }
    
    @objc func toSettingClick(){
        self.inputBox.resignFirstResponder()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25){
            let dest = self.context?.storyboard?.instantiateViewController(withIdentifier: "settingViewController")
            self.context?.show(dest!, sender: self)
        }
    }
    
    @objc func submitClick(_ sender: UIButton)  {
        print("submitClick")
        if var message = inputBox.text, message.count > 0 {
            if showTailCheckBox.isSelected,let tail = Settings.tailContent, tail.count > 0 {
                message = message + "     "+tail
            }
            let len = 13 - message.count
            if len > 0 {
                for _ in 0..<len {
                    message += " "
                }
            }
            
            didSubmitCallback(message,self.isLz,self.pos)
        }
    }
    
    @objc func closeClick(_ sender: UIButton)  {
        print("closeClick")
        hideInputBox()
        didCloseCallback()
    }
    
    public func showInputBox(context:UIViewController, title:String? = nil,isLz:Bool,pos:Int = 0) {
        self.context = context
        self.isHidden = false
        inputBox.becomeFirstResponder()
        placeholderLabel.text = title
        self.isLz = isLz
        self.pos = pos
    }
    
    public func hideInputBox(clear:Bool = false) {
        inputBox.resignFirstResponder()
        self.isHidden = true
        if clear {
            inputBox.text = nil
        }
    }
    
    public func startLoading(text:String? = nil){
        print("replyView->loading...")
        inputBox.isEditable = false
        loadingIndicate.startAnimating()
    }
    
    public func endLoading(){
        inputBox.isEditable = true
        loadingIndicate.stopAnimating()
        print("replyView->end loading")
    }
    
    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
}
