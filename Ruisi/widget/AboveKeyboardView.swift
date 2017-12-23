//
//  AboveKeyboardView.swift
//  Ruisi
//
//  Created by yang on 2017/12/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 软键盘能够顶起的view iPhoneX 适配
class AboveKeyboardView: UIView {
    
    //外部接口用于关闭键盘处理
    public var shouldHandleKeyBoard = true
    public static var keyboardHeight: CGFloat = 0.0
    
    private var keyboardIsVisible = false
    //备份当前的center以便键盘隐藏还原
    private var currentCenter: CGPoint?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForKeyboardNotifications()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForKeyboardNotifications()
    }

    override func layoutSubviews() {
        if currentCenter == nil {
            currentCenter = self.center
        }
    }

    deinit {
        deregisterFromKeyboardNotifications()
    }

    // MARK: Notifications
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    private func deregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    // MARK: Triggered Functions
    /*
     AnyHashable("UIKeyboardCenterBeginUserInfoKey"): NSPoint: {187.5, 775},
     AnyHashable("UIKeyboardIsLocalUserInfoKey"): 1,
     AnyHashable("UIKeyboardCenterEndUserInfoKey"): NSPoint: {187.5, 538},
     AnyHashable("UIKeyboardBoundsUserInfoKey"): NSRect: {{0, 0}, {375, 258}},
     AnyHashable("UIKeyboardFrameEndUserInfoKey"): NSRect: {{0, 409}, {375, 258}},
     AnyHashable("UIKeyboardAnimationCurveUserInfoKey"): 7,
     AnyHashable("UIKeyboardFrameBeginUserInfoKey"): NSRect: {{0, 667}, {375, 216}},
     AnyHashable("UIKeyboardAnimationDurationUserInfoKey"): 0.25
    */

    @objc private func keyboardWillShow(notification: NSNotification) {
        print("will show")
        if !shouldHandleKeyBoard { return }
        keyboardIsVisible = true
        guard let info = notification.userInfo, let rect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        let curveValue = ((info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue) ?? 7
        let duration = (info[UIKeyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: curveValue) ?? UIViewAnimationCurve.easeInOut)
        
        let keyboardHeight = rect.height
        AboveKeyboardView.keyboardHeight = keyboardHeight
        print("keyboardHeight :\(keyboardHeight) keyboardTop:\(rect.origin.y)")
        
        self.center = CGPoint(x: currentCenter!.x, y: currentCenter!.y - keyboardHeight)
        UIView.commitAnimations()
    }

    @objc func keyboardWillBeHidden(notification: NSNotification) {
        print("will hide")
        if !shouldHandleKeyBoard { return }
        keyboardIsVisible = false
        guard let info = notification.userInfo, let rect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        let curveValue = ((info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue) ?? 7
        let duration = (info[UIKeyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: curveValue) ?? UIViewAnimationCurve.easeInOut)
        
        let keyboardHeight = rect.height
        print("keyboardHeight :\(keyboardHeight) keyboardTop:\(rect.origin.y)")
        
        self.center = self.currentCenter!
        UIView.commitAnimations()
    }
}
