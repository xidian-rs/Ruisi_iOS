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
    private var keyboardIsVisible = false
    private var keyboardHeight: CGFloat = 0.0
    private var currentCenter: CGPoint?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForKeyboardNotifications()
    }
    
    override func layoutSubviews() {
        print("layoutSubviews")
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
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        keyboardIsVisible = true
        guard let userInfo = notification.userInfo else {
            return
        }
        if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,keyboardHeight > 0 {
            self.keyboardHeight = keyboardHeight
        }
        let point = userInfo["UIKeyboardCenterEndUserInfoKey"] as! CGPoint
        if !self.isHidden {
            if let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
                let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(duration)
                UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: curve.intValue) ?? UIViewAnimationCurve.easeInOut)
                self.center = CGPoint(x: self.center.x, y: point.y - self.frame.height/2 - keyboardHeight/2 + CGFloat(Settings.safeAeraBottomInset))
                UIView.commitAnimations()
        
                print("move -> height:\(self.currentCenter!.y - (point.y - self.frame.height/2 - keyboardHeight/2))")
            }
        }
    }
    
    @objc private func keyboardWillBeHidden(notification: NSNotification) {
        self.keyboardHeight = 0
        keyboardIsVisible = false
        if !self.isHidden {
            guard let userInfo = notification.userInfo else {
                return
            }
            if let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
                let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                animateHUDWith(duration: duration,curve: UIViewAnimationCurve(rawValue: curve.intValue) ?? UIViewAnimationCurve.easeInOut,
                               toLocation: self.currentCenter!)
            }
        }
    }
    
    private func animateHUDWith(duration: Double, curve: UIViewAnimationCurve, toLocation location: CGPoint) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(TimeInterval(duration))
        UIView.setAnimationCurve(curve)
        self.center = location
        UIView.commitAnimations()
    }
}
