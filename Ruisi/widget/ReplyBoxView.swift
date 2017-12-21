//
//  ReplyBoaxView.swift
//  Ruisi
//
//  Created by yang on 2017/12/6.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ReplyBoxView: AboveKeyboardView {

    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var inputBox: UITextView!
    @IBOutlet weak var clsoeBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var showTailCheckBox: LTHRadioButton!
    @IBOutlet weak var loadingIndicate: UIActivityIndicatorView!
    
    var context: UIViewController?
    var isLz = true
    var pos = 0
    
    class func replyView() -> ReplyBoxView {
        let nib = UINib(nibName: "ReplyBoxView", bundle: nil)
        let v = nib.instantiate(withOwner: nil, options: nil).first as! ReplyBoxView
        return v
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    func xibSetup() {
        print("\(type(of: self))")

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
    

    private var didSubmitCallback: (_ content: String?, _ isLz: Bool, _ pos: Int) -> Void = { _, _, _ in
        
    }

    private var didCloseCallback: () -> Void = {
        
    }



    public func onSubmit(execute closure: @escaping (_ content: String?, _ isLz: Bool, _ pos: Int) -> Void) {
        didSubmitCallback = closure
    }

    public func onClose(execute closure: @escaping () -> Void) {
        didCloseCallback = closure
    }

    @IBAction func toSettingClick(_ sender: UIButton) {
        self.inputBox.resignFirstResponder()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            let dest = self.context?.storyboard?.instantiateViewController(withIdentifier: "settingViewController")
            self.context?.show(dest!, sender: self)
        }
    }
    
 
    @objc func submitClick(_ sender: UIButton) {
        print("submitClick")
        if var message = inputBox.text, message.count > 0 {
            if showTailCheckBox.isSelected, let tail = Settings.tailContent, tail.count > 0 {
                message = message + "     " + tail
            }
            let len = 13 - message.count
            if len > 0 {
                for _ in 0..<len {
                    message += " "
                }
            }

            didSubmitCallback(message, self.isLz, self.pos)
        }
    }

    @objc func closeClick(_ sender: UIButton) {
        print("closeClick")
        hideInputBox()
        didCloseCallback()
    }

    public func showInputBox(context: UIViewController, title: String? = nil, isLz: Bool, pos: Int = 0) {
        self.context = context
        self.isHidden = false
        inputBox.becomeFirstResponder()
        placeholderLabel.text = title
        self.isLz = isLz
        self.pos = pos
    }

    public func hideInputBox(clear: Bool = false) {
        inputBox.resignFirstResponder()
        self.isHidden = true
        if clear {
            inputBox.text = nil
        }
    }

    public func startLoading(text: String? = nil) {
        inputBox.isEditable = false
        loadingIndicate.startAnimating()
    }

    public func endLoading() {
        inputBox.isEditable = true
        loadingIndicate.stopAnimating()
    }
    
    @IBAction func toAtClick(_ sender: Any) {
        let dest = self.context?.storyboard?.instantiateViewController(withIdentifier: "chooseFriendViewNavigtion") as! UINavigationController
        if let vc = dest.topViewController as? ChooseFriendViewController {
            vc.delegate = { names in // 选择过后调用
                print(names)
                var result: String = ""
                names.forEach { (name) in
                    result += " @\(name)"
                }
                if names.count > 0 {
                    result += " "
                }
                
                self.inputBox.insertText(result)
            }
            self.context?.present(dest, animated: true, completion: nil)
        }
    }
}
