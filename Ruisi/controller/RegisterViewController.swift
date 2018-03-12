//
//  RegisterViewController.swift
//  Ruisi
//
//  Created by yang on 2018/3/11.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit
import Kanna

class RegisterViewController: UITableViewController {
    
    @IBOutlet weak var inviteCodeInput: UITextField!
    @IBOutlet weak var userNameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var confirmPasswordInput: UITextField!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var idCodeInput: UITextField!
    @IBOutlet weak var realNameInput: UITextField!
    
    @IBOutlet weak var inviteCodeErrText: UILabel!
    @IBOutlet weak var usernameErrText: UILabel!
    @IBOutlet weak var passwordErrText: UILabel!
    @IBOutlet weak var confirmPasswordErrText: UILabel!
    @IBOutlet weak var emailErrText: UILabel!
    
    private var sex = 0 //0 1 2
    private var progress: UIAlertController!
    
    // 验证码相关
    private var haveValid = false
    private var seccodehash: String?
    private var validValue: String? //验证码输入值
    private var inputValidVc: InputValidController?
    
    private var usernameKey: String?
    private var passwordKey: String?
    private var confirmPasswordKey: String?
    private var emailKey: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inviteCodeInput.addTarget(self, action: #selector(inviteCodeEndInput), for: .editingDidEnd)
        userNameInput.addTarget(self, action: #selector(usernameEndInput), for: .editingDidEnd)
        passwordInput.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        confirmPasswordInput.addTarget(self, action: #selector(confirmPasswordChanged), for: .editingChanged)
        emailInput.addTarget(self, action: #selector(emailEndInput), for: .editingDidEnd)
        
        inviteCodeErrText.isHidden = true
        usernameErrText.isHidden = true
        passwordErrText.isHidden = true
        confirmPasswordErrText.isHidden = true
        emailErrText.isHidden = true
        
        progress = UIAlertController(title: "提交中", message: "请稍后...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 13, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = .gray
        loadingIndicator.startAnimating();
        progress.view.addSubview(loadingIndicator)
        progress.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        loadContent()
    }
    
    private var postForms = [String: String]()
    
    func loadContent()  {
        //TODO 目前只有校园网才可以注册
        // 管理后台可打开允许手机版注册
        HttpUtil.GET(url: "\(Urls.baseUrl)member.php?mod=register\(App.isSchoolNet ? "" : "&mobile=2")", params: nil) { [weak self] (ok, res) in
            var success = false
            if ok { //检查验证码
                let start = res.range(of: "seccode_")?.upperBound
                if let s = start {
                    let end = res.range(of: "\"", range: s ..< res.endIndex)!.lowerBound
                    self?.seccodehash = String(res[s..<end])
                    self?.haveValid = true
                    print("需要验证码 \(self?.seccodehash ?? "")")
                }
            }
            
            if ok, let node = try? HTML(html: res, encoding: .utf8) ,let this = self {
                let trs = node.xpath("//form[@id=\"registerform\"]//tr")
                for tr in trs {
                    success = true
                    if let label = tr.css("label").first, let input = tr.css("input").first {
                        if (input["id"]?.count ?? 0) > 0 {
                            if label.text!.contains("用户名:") {
                                self?.usernameKey = input["id"]!
                            } else if label.text!.contains("确认密码:") {
                                self?.confirmPasswordKey = input["id"]!
                            } else if label.text!.contains("密码:") {
                                self?.passwordKey = input["id"]!
                            } else if label.text!.contains("Email:") {
                                self?.emailKey = input["id"]!
                            }
                            
                            print("==>",input["id"]!, input["value"] ?? "")
                            this.postForms[input["id"]!] = input["value"]
                        }
                    }
                }
            }
            
            if !success {
                DispatchQueue.main.async {
                    self?.showBackAlert(title: "提示信息", message: App.isSchoolNet ?
                        "论坛暂停注册，将不定期开放邀请注册。敬请关注论坛公告。" : "论坛暂停注册，或者外网目前无法使用注册功能，请切换到校园网")
                }
            }
        }
    }
    
    
    @objc private func inviteCodeEndInput(_ sender: UITextField) {
        checkInput(text: sender.text, index: 1, label: inviteCodeErrText)
    }
    
    @objc private func usernameEndInput(_ sender: UITextField) {
        checkInput(text: sender.text, index: 2, label: usernameErrText)
    }
    
    @objc private func passwordChanged(_ sender: UITextField) {
        if (sender.text?.count ?? 0) < 6 {
            passwordErrText.isHidden = false
            passwordErrText.text = "密码不足6位"
        } else {
            passwordErrText.isHidden = true
        }
    }
    
    @objc private func confirmPasswordChanged(_ sender: UITextField) {
        if (sender.text ?? "") == (passwordInput.text ?? "") {
            confirmPasswordErrText.isHidden = true
        } else {
            confirmPasswordErrText.text = "2次密码不匹配"
            confirmPasswordErrText.isHidden = false
        }
    }
    
    @objc private func emailEndInput(_ sender: UITextField) {
        checkInput(text: sender.text, index: 5, label: emailErrText)
    }
    
    @IBAction func registerClick(_ sender: UIBarButtonItem? = nil) {
        let inviteCode = inviteCodeInput.text
        let username = userNameInput.text
        let password = passwordInput.text
        let confirmPassword = confirmPasswordInput.text
        let email = emailInput.text
        let idNum = idCodeInput.text
        let realName = realNameInput.text
        
        var err: String?
        if inviteCode == nil || inviteCode!.count == 0 {
            err = "请填写邀请码"
        } else if username == nil || username!.count == 0 {
            err = "请填写用户名"
        } else if password == nil || password!.count == 0 {
            err = "请填写密码"
        } else if password! != (confirmPassword ?? "") {
            err = "确认密码不匹配"
        } else if email == nil || email!.count == 0 {
            err = "请填写邮箱"
        }
        
        
        if let e = err {
            alert(message: e)
            return
        }
        
        postForms["invitecode"] = inviteCode
        if let keyU = usernameKey {
            postForms[keyU] = username
        }
        
        if let keyP = passwordKey {
            postForms[keyP] = password
        }
        
        if let keyCP = confirmPasswordKey {
            postForms[keyCP] = confirmPassword
        }
        
        if let keyE = emailKey {
            postForms[keyE] = email
        }
        
        postForms["field1"] = idNum
        postForms["gender"] = String(sex)
        postForms["realname"] = realName
        
        if haveValid && validValue == nil {
            showInputValidDialog()
            return
        }
        
        if self.haveValid { //是否有验证码
            postForms["seccodehash"] = self.seccodehash!
            postForms["seccodeverify"] = self.validValue!
        }
        
        present(progress, animated: true, completion: nil)
        
        HttpUtil.POST(url: "member.php?mod=register\(App.isSchoolNet ? "" : "&mobile=2")", params: postForms) { (ok, res) in
            //抱歉，验证码填写错误
            var success = false
            var message: String
            if ok {
                let jumpIndex = res.range(of: "class=\"alert_error\"")?.upperBound
                if let jump = jumpIndex {
                    success = false
                    let start = res.range(of: "<p>", range: jump ..< res.endIndex)!.upperBound
                    let end = res.range(of: "</p>", range: jump ..< res.endIndex)!.lowerBound
                    message = String(res[start..<end])
                } else {
                    success = true
                    message = "注册成功!你要返回关闭此页面吗？"
                }
            } else {
                success = false
                message = res
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.progress.dismiss(animated: true) {
                    if !success && message.contains("验证码填写错误") {
                        self?.showInputValidDialog()
                    } else {
                        let alert = UIAlertController(title: success ? "注册成功!" : "错误", message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                        if success {
                            alert.addAction(UIAlertAction(title: "返回", style: .default) { action in
                                self?.navigationController?.popViewController(animated: true)
                            })
                        }
                        
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    
    }
    
    
    @IBAction func sexChange(_ sender: UISegmentedControl) {
        sex = sender.selectedSegmentIndex
    }
    
    
    
    private func checkInput(text: String?, index: Int, label: UILabel?) {
        guard let s = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), s.count > 0 else {
            label?.text = "输入不能为空"
            label?.isHidden = false
            
            return
        }
        
        var params = [String:String]()
        switch index {
        case 1: //邀请码
            params["action"] = "checkinvitecode"
            params["invitecode"] = s
        case 2: //用户名
            params["action"] = "checkusername"
            params["username"] = s
        case 5: //邮箱
            params["action"] = "checkemail"
            params["email"] = s
        default:
            return
        }
        
        
        HttpUtil.GET(url: Urls.regCheckUrl, params: params) { (ok, res) in
            var reason: String?
            var success = false
            if ok {
                if res.contains("CDATA[succeed]") || res.contains("<p>succeed</p>") {
                    success = true
                    print("可用 \(s)")
                } else {
                    if let s = res.range(of: "[CDATA[")?.upperBound ,let e =  res.range(of: "]]></root>")?.lowerBound {
                        if let html = try? HTML(html: res, encoding: .utf8) {
                            reason = html.css("p").first?.text ?? html.text ?? res
                        } else {
                            reason = String(res[s..<e])
                        }
                    } else {
                        reason = "输入错误"
                    }
                }
            }
            
            DispatchQueue.main.async {
                if success {
                    label?.isHidden = true
                } else {
                    if let r = reason {
                        label?.text = r
                        label?.isHidden = false
                    } else {
                        label?.isHidden = true
                    }
                }
            }
        }
    }
    
    // 验证码输入框回调
    // click 是否点击的确认
    func validInputChange(click: Bool, hash: String, value: String) {
        self.seccodehash = hash
        self.validValue = value
        if click {
            self.registerClick()
        }
    }
    
    // 显示输入验证码的框
    func showInputValidDialog() {
        if inputValidVc == nil {
            inputValidVc = InputValidController(hash: self.seccodehash!, update: nil)
            inputValidVc?.delegate = validInputChange
        }
        inputValidVc?.show(vc: self)
    }
    
    func alert(title: String? = "注册错误", message: String) {
        let vc = UIAlertController(title: "注册错误", message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
        self.present(vc, animated: true)
    }
}
