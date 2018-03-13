//
//  ForgetPasswordController.swift
//  Ruisi
//
//  Created by yang on 2018/3/11.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit
import Kanna

class ForgetPasswordController: UIViewController {

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var noticeLabel: HtmlLabel!
    private var progress: UIAlertController!
    
    let messageText = """
    <b>无法访问校园网的用户注意</b><br>
    找回密码成功后系统会给你的邮件发送一封邮件，邮件里面的链接只有校园网才能访问，需要修改链接<br>
    修改前：http://rs.xidian...id=XXX<br>
    修改后：http://rs<font color="red">bbs</font>.xidian...id=XXX<font color="red">&mobile=2</font>
    """
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "提交", style: .plain, target: self, action: #selector(submitClick))

        progress = UIAlertController(title: "提交中", message: "请稍后...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 13, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = .gray
        loadingIndicator.startAnimating();
        progress.view.addSubview(loadingIndicator)
        progress.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        noticeLabel.attributedText = AttributeConverter(font: UIFont.systemFont(ofSize: 14), textColor: UIColor.gray).convert(src: messageText)
    }
    
    @objc private func submitClick() {
        emailInput.resignFirstResponder()
        usernameInput.resignFirstResponder()
        
        guard  (emailInput.text ?? "").count > 0 else {
            showAlert(title: "错误", message: "请填写邮箱")
            return
        }
        
        var params:[String: Any] = ["handlekey":"lostpwform","email": emailInput.text!]
        if let u = usernameInput.text {
            params["username"] = u
        }
        
        present(progress, animated: true, completion: nil)
        HttpUtil.POST(url: Urls.forgetPasswordUrl, params: params, callback: { [weak self] (ok, res) in
            //print(res)
            var reason: String?
            var success = false
            if ok {
                if res.contains("取回密码的方法已通过") {
                    success = true
                    reason = "取回密码的方法已通过 Email 发送到您的信箱中，请尽快修改您的密码"
                } else if let html = try? HTML(html: res, encoding: .utf8) {
                    reason = html.text
                } else {
                    reason = res
                }
            } else {
                reason = res
            }
            
            DispatchQueue.main.async {
                self?.progress.dismiss(animated: true) {
                    self?.showAlert(title: success ? "操作成功" : "错误", message: reason ?? (success ? "重置密码邮件已经发送到你的邮箱" : "未知错误"))
                }
            }
        })
    }

}
