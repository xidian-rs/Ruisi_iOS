//
//  Extension.swift
//  Ruisi
//
//  Created by yang on 2017/11/29.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension String {
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }

    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
}

extension UILabel {
    func textHeight(for width: CGFloat) -> CGFloat {
        guard let text = text else {
            return 0
        }
        return text.height(for: width, font: font)
    }
    
    func attributedTextHeight(for width: CGFloat) -> CGFloat {
        guard let attributedText = attributedText else {
            return 0
        }
        return attributedText.height(for: width)
    }
}

extension String {
    func height(for width: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [NSAttributedStringKey.font: font], context: nil)
        return actualSize.height
    }
}

extension NSAttributedString {
    func height(for width: CGFloat) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], context: nil)
        return actualSize.height
    }
}

extension UIImage {
    func scaleToWidth(width: CGFloat) -> UIImage {
        if self.size.width <= width {
            return self
        }
        
        let alpha = false
        let height = self.size.height / (self.size.width / width)
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, alpha, 0.0)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        self.draw(in: rect)
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //调整大小
    func scaleToSizeAndWidth(width: CGFloat, maxSize: Int) -> Data? {
        let image = self.scaleToWidth(width: width) //原始缩放过后的image
        guard var imageData = UIImageJPEGRepresentation(image, 1.0) else {
            return nil
        }
        
        var sizeKb = (imageData as NSData).length / 1024
        var resizeRate: CGFloat = 0.9
        
        while sizeKb > maxSize && resizeRate > 0.1 {
            imageData = UIImageJPEGRepresentation(image, resizeRate)!
            sizeKb = (imageData as NSData).length / 1024
            resizeRate -= 0.1
        }
        
        return imageData
    }
}

extension UIViewController {
    // 检测是否登陆 如果登录 返回true 如果没有登陆显示弹窗
    func checkLogin(message: String?) -> Bool {
        if !App.isLogin || App.uid == nil {
            showLoginAlert(message: message ?? "你需要登陆才能执行此操作")
            return false
        }
        
        return true
    }
    
    func showLoginAlert(message: String? = nil) {
        let alert = UIAlertController(title: "需要登陆", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "登陆", style: .default, handler: { (alert) in
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
            self.present(dest!, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showBackAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "关闭", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "好", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    func loadWebView(title: String?, url: URL) {
        
        let vc = UIViewController()
        let webview = WKWebView(frame: view.frame)
        
        webview.load(URLRequest(url: url))
        
        vc.view.addSubview(webview)
        vc.title = title ?? "网页"
        
        self.show(vc, sender: self)
    }
}
