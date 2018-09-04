//
//  PasswordViewController.swift
//  Ruisi
//
//  Created by yang on 2018/9/2.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit
import Kanna

// 密码安全
// 1. 修改密码
// 2. 修改邮箱
class PasswordViewController: UIViewController {

    public var mode: Int = 2
    
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var newPasswordLabel: UILabel!
    @IBOutlet weak var newPasswordInput: UITextField!
    @IBOutlet weak var confirmNewPasswordLabel: UILabel!
    @IBOutlet weak var confirmNewPasswordInput: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var emailNotifyInput: UILabel!
    @IBOutlet weak var resentBtn: UIButton!
    @IBOutlet weak var submitBtn: UIBarButtonItem!
    
    // 验证码相关
    private var haveValid = false
    private var seccodehash: String?
    private var validUpdate: String?
    private var validValue: String? //验证码输入值
    private var inputValidVc: InputValidController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mode == 1 {
            emailLabel.isHidden = true
            emailInput.isHidden = true
            emailNotifyInput.isHidden = true
            resentBtn.isHidden = true
        } else {
            newPasswordLabel.isHidden = true
            newPasswordInput.isHidden = true
            confirmNewPasswordLabel.isHidden = true
            confirmNewPasswordInput.isHidden = true
        }
        
        submitBtn.title = title
        emailNotifyInput.isHidden = true
        
        loadData()
    }
    
    func loadData(show: Bool = false) {
        HttpUtil.GET(url: Urls.passwordSafeUrl, params: nil) { [weak self] ok, res in
            var errorTitle: String?
            var errorContent: String?
            
            if ok, let s = res.range(of: "[CDATA[")?.upperBound ,let e =  res.range(of: "]]></root>")?.lowerBound {
                if let html = try? HTML(html: String(res[s..<e]), encoding: .utf8) {
                    let hash = html.css("input[name=formhash]").first?["value"]
                    if hash != nil {
                        Settings.formhash = hash
                        print("formHash:\(hash!)")
                    }
                    
                    if let start = html.innerHTML?.range(of: "updateseccode('")?.upperBound {
                        let end = html.innerHTML!.range(of: "',")!.lowerBound
                        self?.haveValid = true
                        self?.seccodehash = String(html.innerHTML![start..<end])
                        //print("有验证码 \(self?.seccodehash!)")
                    }

                    let email = html.css("input[name=emailnew]").first?["value"]
                    print("email:\(email ?? "")")
                    let notify: String?
                    let emailValid = html.innerHTML?.contains("等待验证中...") ?? false
                    print("=========")
                    if self?.mode == 2, let eStart = html.innerHTML?.range(of: "新邮箱(")?.lowerBound, let eEnd = html.innerHTML?.range(of: ")等待验证中...", range: eStart..<html.innerHTML!.endIndex)?.upperBound {
                        notify = String(html.innerHTML![eStart..<eEnd])
                    } else {
                        notify = nil
                    }
                    
                    if email != nil {
                        DispatchQueue.main.async {
                            self?.emailInput.text = email
                            self?.resentBtn.isHidden = (self?.mode ?? 1 == 1 || !emailValid)
                            if let n = notify {
                                self?.emailNotifyInput.isHidden = false
                                self?.emailNotifyInput.text = n
                            } else {
                                self?.emailNotifyInput.isHidden = true
                            }
                        }
                    }
                } else {
                    errorTitle = "解析失败"
                    errorContent = "请联系开发者"
                }
            } else {
                errorTitle = "加载失败"
                errorContent = "信息失败，是否重新加载"
            }
            
            if let t = errorTitle {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: t, message: errorContent!, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "重新加载", style: .default, handler: { (alert) in
                        self?.loadData()
                    }))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    var loadingView: UIAlertController?
    
    func showLoadingView() {
        if loadingView == nil {
            loadingView = UIAlertController(title: "提交中", message: "请稍后...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .gray
            loadingIndicator.startAnimating()
            loadingView!.view.addSubview(loadingIndicator)
        }
        present(loadingView!, animated: true)
    }
    
    // 处理软键盘
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func submitClick(_ sender: Any? = nil) {
        passwordInput.resignFirstResponder()
        if !newPasswordInput.isHidden {
            newPasswordInput.resignFirstResponder()
        }
        
        if !confirmNewPasswordInput.isHidden {
            confirmNewPasswordInput.resignFirstResponder()
        }
        
        if !emailInput.isHidden {
            emailInput.resignFirstResponder()
        }
        
        let password = passwordInput.text ?? ""
        if password.count  <= 0 {
            alert(message: "密码不能为空")
            return
        }
        
        var params: [String : Any] = ["oldpassword" : password]
        if mode == 1 { // 修改密码
            let newPassword = newPasswordInput.text ?? ""
            let newConfirmPassword = confirmNewPasswordInput.text ?? ""
            if newPassword !=  newConfirmPassword {
                alert(message: "确认新密码不匹配")
                return
            }
            
            if newPassword.count < 6 {
                alert(message: "新密码最少6位")
                return
            }
            
            params["newpassword"] = newPassword
            params["newpassword2"] = newConfirmPassword
        } else {
            if (emailInput.text ?? "").count == 0 {
                alert(message: "邮箱不能为空")
                return
            }
        }
        
        params["pwdsubmit"] = true
        params["passwordsubmit"] = true
        params["emailnew"] = emailInput.text ?? ""
        
        if haveValid && validValue == nil {
            showInputValidDialog()
            return
        }
        
        if haveValid {
            params["seccodemodid"] = "home::spacecp"
        }
        
        if self.haveValid { //是否有验证码
            params["seccodehash"] = self.seccodehash!
            params["seccodeverify"] = self.validValue!
        }
        
        showLoadingView()
        HttpUtil.POST(url: Urls.passwordSafePostUrl, params: params, callback: { [weak self] ok, res in
            var title: String?
            var content: String?
            var success = false
            
            if ok {
                content = Utils.getRuisiReqAjaxError(res: res)
                if content != nil {
                    if self?.mode == 1 && content?.contains("个人资料保存成功") ?? false {
                        success = true
                        title = "操作成功"
                        Settings.uid = nil
                        print("退出登陆")
                        content = "密码修改成功请重新登录"
                    } else if (self?.mode == 2 && content?.contains("确认 Email 已发送") ?? false) || content?.contains("个人资料保存成功") ?? false {
                        success = true
                        title = "操作成功"
                    } else {
                        title = "操作失败"
                    }
                } else {
                    title = "操作失败"
                }
            } else {
                title = "加载失败"
                content = res
            }
            
            let vc = UIAlertController(title: title, message: content, preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                if success {
                    self?.dismiss(animated: true, completion: nil)
                }
            }))
            
            self?.dismiss(animated: true, completion: {
                self?.present(vc, animated: true)
            })
        })
    }
    
    func alert(title: String? = "错误", message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
        self.present(vc, animated: true)
    }
    
    // 验证码输入框回调
    // click 是否点击的确认
    func validInputChange(click: Bool, hash: String, value: String) {
        self.seccodehash = hash
        self.validValue = value
        if click {
            self.submitClick()
        }
    }
    
    // 显示输入验证码的框
    func showInputValidDialog() {
        if let sechash = self.seccodehash {
            if inputValidVc == nil {
                inputValidVc = InputValidController(hash: sechash, update: self.validUpdate)
                inputValidVc?.delegate = validInputChange
            }
            inputValidVc?.show(vc: self)
        } else {
            loadData(show: true)
        }
    }
    
    @IBAction func dismissClick(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resentClick(_ sender: Any) {
        showLoadingView()
        HttpUtil.GET(url: Urls.resentEmailUrl, params: nil) { [weak self] (ok, res) in
            let title = ok ? "提交结果" : "提交失败"
            let message = ok ? (Utils.getRuisiReqAjaxError(res: res) ?? "未知错误") : res
            
            let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            self?.dismiss(animated: true, completion: {
                self?.present(vc, animated: true)
            })
        }
    }
}
