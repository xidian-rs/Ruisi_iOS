//
//  Extension.swift
//  Ruisi
//
//  Created by yang on 2017/11/29.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }

    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
}

extension UIViewController {
    // 检测是否登陆 如果登录 返回true 如果没有登陆显示弹窗
    func checkLogin(message: String?) -> Bool {
        if !App.isLogin || App.uid == nil {
            let alert = UIAlertController(title: "需要登陆", message: message ?? "你需要登陆才能执行此操作", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "登陆", style: .default, handler: { (alert) in
                let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
                self.present(dest!, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            return false
        }
        
        return true
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
}
