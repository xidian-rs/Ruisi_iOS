//
//  LoginViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna
import Kingfisher

// 登陆页面
class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var remberSwitch: UISwitch!
    @IBOutlet weak var questBtn: UIButton!
    @IBOutlet weak var questInput: UITextField!
    
    private var answerSelect = 0
    private let quests = ["请选择(未设置选此)", "母亲的名字", "爷爷的名字", "父亲出生的城市", "您其中一位老师的名字", "您个人计算机的型号", "您最喜欢的餐馆名称", "驾驶执照最后四位数字"]

    // 验证码相关
    private var haveValid = false
    private var seccodehash: String?
    private var validUpdate: String?
    private var validValue: String? //验证码输入值
    private var inputValidVc: InputValidController?
    
    private var username: String {
        return usernameTextField.text ?? ""
    }
    
    private var password: String {
        return passwordTextField.text ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Settings.remberPassword {
            remberSwitch.isOn = true
            usernameTextField.text = Settings.username
            passwordTextField.text = Settings.password
        }

        loadData()
    }
    
    func selectQuest(action: UIAlertAction) {
        self.questBtn.setTitle(action.title, for: .normal)
        for i in 0..<quests.count {
            if quests[i] == action.title {
                answerSelect = i
                break
            }
        }
        questInput.isHidden = (answerSelect == 0)
    }
    
    @IBAction func questBtnClick(_ sender: Any) {
        let sheet = UIAlertController(title: "安全提问", message: nil, preferredStyle: .actionSheet)
        for item in quests {
            let action = UIAlertAction(title: item, style: .default, handler: selectQuest)
            sheet.addAction(action)
        }
        
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func cencelClick(_ sender: Any) {
        // self.dismiss(animated: true, completion: nil)
        presentingViewController?.dismiss(animated: true)
    }
    
    func alert(title: String? = "登陆错误", message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
        self.present(vc, animated: true)
    }
    
    func loadData(show: Bool = false) {
        HttpUtil.GET(url: Urls.checkLoginUrl, params: nil) { [weak self] ok, res in
            var errorTitle: String?
            var errorContent: String?
            
            if ok {
                if res.contains("欢迎您回来") {
                    print("你现在是登陆状")
                    self?.loginResult(isok: true, res: res, haveLoadingView: false)
                    return
                } else {
                    print("不是登陆状态")
                    if let s = res.range(of: "[CDATA[")?.upperBound ,let e =  res.range(of: "]]></root>")?.lowerBound {
                        if let html = try? HTML(html: String(res[s..<e]), encoding: .utf8) {
                            let hash = html.css("input#formhash").first?["value"]
                            if hash != nil {
                                Settings.formhash = hash
                                print("formHash:\(hash!)")
                            }
                            
                            let sechash = html.css("input[name=seccodehash]").first?["value"]
                            if sechash != nil {
                                self?.haveValid = true
                                self?.seccodehash = sechash
                                print("有验证码 \(sechash!)")
                            }
                            
                            if show {
                                self?.showInputValidDialog()
                            }
                        }
                    }
                }
            } else {
                errorTitle = "加载失败"
                errorContent = "加载登陆信息失败，是否重新加载"
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
    
    @IBAction func loginClick(_ sender: UIBarButtonItem? = nil) {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        if !questInput.isHidden {
            questInput.resignFirstResponder()
        }

        if self.username.count <= 0 {
            alert(message: "用户名不能为空")
            return
        }
        
        if self.password.count <= 0 {
            alert(message: "密码不能为空")
            return
        }
        
        if haveValid && validValue == nil {
            showInputValidDialog()
            return
        }

        let username = self.username
        let password = self.password
        let answer = answerSelect == 0 ? "" : questInput.text ?? ""
        
        var params: [String : Any] = ["username": username, "password": password, "fastloginfield": "username", "cookietime": "2592000", "questionid": self.answerSelect, "answer": answer]
        
        if self.haveValid { //是否有验证码
            params["seccodehash"] = self.seccodehash!
            params["seccodeverify"] = self.validValue!
        }
        
        showLoadingView()
        HttpUtil.POST(url: Urls.loginUrl + "&loginsubmit=yes", params: params, callback: { [weak self] ok, res in
            if ok {
                if res.contains("欢迎您回来") {
                    self?.loginResult(isok: true, res: res)
                } else if res.contains("抱歉，验证码填写错误") {
                    DispatchQueue.main.async {
                        self?.dismiss(animated: true, completion: {
                            self?.showInputValidDialog()
                        })
                    }
                } else if res.contains("登录失败") && res.contains("您还可以尝试") {
                    let start = res.range(of: "登录失败")!.lowerBound
                    let end = res.range(of: "</p>", range: start..<res.endIndex)!.lowerBound
                    self?.loginResult(isok: false, res: String(res[start..<end]))
                } else if res.contains("密码错误次数过多") {
                    let start = res.range(of: "密码错误次数过多")!.lowerBound
                    let end = res.range(of: "</p>", range: start..<res.endIndex)!.lowerBound
                    self?.loginResult(isok: false, res: String(res[start..<end]))
                } else {
                    self?.loginResult(isok: false, res: "账号或密码错误")
                }
            } else {
                self?.loginResult(isok: false, res: res)
            }
        })
    }
    
    
    // 验证码输入框回调
    // click 是否点击的确认
    func validInputChange(click: Bool, hash: String, value: String) {
        self.seccodehash = hash
        self.validValue = value
        if click {
            loginClick()
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
    
    func loginResult(isok: Bool = false, res: String, haveLoadingView: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            let vc: UIAlertController
            if !isok {
                vc = UIAlertController(title: "登陆失败", message: res, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
            } else {
                let start = res.range(of: "欢迎您回来")!.upperBound
                let end = res.range(of: "</p>", range: start..<res.endIndex)!.lowerBound
                
                let info = res[start..<end].components(separatedBy: "，")
                let name: String
                let grade: String
                if res.range(of: "</font>", range: start..<res.endIndex) != nil {
                    //"<p>欢迎您回来，<font color=\"#0099FF\">实习版主</font> 激萌路小叔，现在将转入登录前页面</p>"
                    grade = String(info[1][info[1].range(of: "\">")!.upperBound..<info[1].range(of: "</font>")!.lowerBound])
                    name = info[1].components(separatedBy: " ").last!
                } else {
                    //"<p>欢迎您回来，实习版主 激萌路小叔，现在将转入登录前页面</p>"
                    name = info[1].components(separatedBy: " ")[1]
                    grade = info[1].components(separatedBy: " ")[0]
                }
                
                let indexStart = res.range(of: "home.php?mod=space", range: start..<res.endIndex)!.upperBound
                let indexEnd = res.range(of: "</a>", range: indexStart..<res.endIndex)!.lowerBound
                let uid = Utils.getNum(from: String(res[indexStart..<indexEnd]))!
                
                let hashStart = res.range(of: "member.php?mod=logging", range: start..<res.endIndex)!.upperBound
                let hashEnd = res.range(of: "</a>", range: hashStart..<res.endIndex)!.lowerBound
                let formhash = Utils.getFormHash(from: String(res[hashStart..<hashEnd]))
                
                print("name: \(name) grade: \(grade) uid:\(uid) formhash:\(formhash ?? "")")
                
                Settings.uid = uid
                Settings.username = name
                Settings.grade = grade
                Settings.formhash = formhash
                
                //记住密码
                if let on = self?.remberSwitch.isOn, on {
                    print("保存用户名和密码")
                    Settings.password = self?.password
                    Settings.remberPassword = true
                } else {
                    Settings.password = nil
                    Settings.remberPassword = false
                }
                
                vc = UIAlertController(title: "登陆成功", message: "欢迎[\(grade) \(name)]", preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                    self?.dismiss(animated: true, completion: nil)
                }))
            }
            
            // 取消loading
            if haveLoadingView {
                self?.dismiss(animated: true, completion: {
                    self?.present(vc, animated: true)
                })
            } else {
                self?.present(vc, animated: true)
            }
        }
    }
    
    var loadingView: UIAlertController?
    
    func showLoadingView() {
        if loadingView == nil {
            loadingView = UIAlertController(title: "登陆中", message: "请稍后...", preferredStyle: .alert)
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
}
