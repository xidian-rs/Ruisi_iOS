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
    
    private var loginUrl: String?
    
    // 验证码相关
    private var haveValid = false
    private var validInputTextField: UITextField!
    private var validImageView: UIImageView!
    private var seccodehash: String?
    private var validValue: String? //验证码输入值
    private var validImageSrc: String? //验证码图片地址
    
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
        let vc = UIAlertController(title: "登陆错误", message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
        self.present(vc, animated: true)
    }
    
    func loadData() {
        HttpUtil.GET(url: Urls.loginUrl, params: nil) { [weak self] ok, res in
            if ok {
                if res.contains("欢迎您回来") {
                    print("cookie is still work login ok")
                    self?.loginResult(isok: true, res: res)
                    return
                }
                
                if let _ = res.index(of: "sec_code vm"), let doc = try? HTML(html: res, encoding: .utf8) {
                    self?.haveValid = true
                    self?.seccodehash =  doc.xpath("//*[@name=\"seccodehash\"]").first?["value"]
                    self?.validImageSrc = doc.xpath("//*[@id=\"loginform\"]/div[1]/div/img").first?["src"]
                }
                
                if let start = res.endIndex(of: "action=\"") {
                    let substr = String(res[start...])
                    let end = substr.index(of: "\"")
                    self?.loginUrl = String(substr[..<end!])
                    return
                }
            }
            
            let alert = UIAlertController(title: "加载失败", message: "是否重新加载", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .destructive, handler: { (alert) in
                self?.dismiss(animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "重新加载", style: .default, handler: { (alert) in
                self?.loadData()
            }))
            self?.present(alert, animated: true)
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
        
        showLoadingView()
        let username = self.username
        let password = self.password
        let answer = answerSelect == 0 ? "" : questInput.text ?? ""
        
        var params: [String : Any] = ["username": username, "password": password, "fastloginfield": "username", "cookietime": "2592000", "questionid": self.answerSelect, "answer": answer]
        if self.haveValid { //是否有验证码
            params["seccodehash"] = self.seccodehash!
            params["seccodeverify"] = self.validValue!
        }
        
        HttpUtil.POST(url: self.loginUrl!, params: params, callback: { ok, res in
            if ok && res.contains("欢迎您回来") {
                self.loginResult(isok: true, res: res)
            } else if res.contains("抱歉，验证码填写错误") {
                self.dismiss(animated: true, completion: {
                    self.showInputValidDialog()
                })
            } else {
                self.loginResult(isok: false, res: "账号或密码错误")
            }
        })
    }
    
    // 显示输入验证码的框
    func showInputValidDialog() {
        let alert = UIAlertController(title: "验证码\n\n", message: nil, preferredStyle: .alert)
        let margin: CGFloat = 10.0
        let width = alert.view.frame.size.width
        let rect = CGRect(x: width / 2 - 100 , y: margin + 35, width: 100, height: 50)
        validImageView = UIImageView(frame: rect)
        validImageView.isUserInteractionEnabled = true
        validImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeValid)))
        alert.view.addSubview(validImageView)

        alert.addTextField { (textField) in
            textField.placeholder = "验证码"
            self.validInputTextField = textField
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (alert) in
            if let text = self.validInputTextField.text, text.count > 2 {
                self.validValue = text
                self.loginClick()
            } else {
                self.validValue = nil
            }
        }))
        self.present(alert, animated: true)
        loadValidImage(hash: self.seccodehash!, url: self.validImageSrc!)
    }
    
    // 换一个验证码图片
    @objc func changeValid()  {
        let hash = "S\(100 +  (arc4random() % 101))"
        self.seccodehash = hash
        self.validValue = nil
        self.validInputTextField.text = nil
        loadValidImage(hash: hash, url: self.validImageSrc!)
    }
    
    
    // 加载验证码图片
    func loadValidImage(hash: String, url: String) {
        var u = url
        if !url.contains(hash) {
            //misc.php?mod=seccode&update=27663&idhash=SszZ1&mobile=2
            let start = url.range(of: "idhash=")!.upperBound
            let end = url.range(of: "&mobile=2")!.lowerBound
            u.replaceSubrange(start..<end, with: hash)
            self.validImageSrc = u
        }
        
        HttpUtil.GET_VALID_IMAGE(url: u) { (ok, data) in
            if ok, let d = data {
                DispatchQueue.main.async {
                    self.validImageView.image =   UIImage.gif(data: d)
                }
            }
        }
    }

    func loginResult(isok: Bool = false, res: String) {
        print("=== login result \(isok) ===")
        DispatchQueue.main.async { [weak self] in
            let vc: UIAlertController
            if !isok {
                vc = UIAlertController(title: "登陆失败", message: res, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
            } else {
                let start = res.range(of: "欢迎您回来")!.upperBound
                let end = res.range(of: "</p>", range: start..<res.endIndex)!.lowerBound
                let info = res[start..<end].components(separatedBy: "，")
                let name = info[1].components(separatedBy: " ")[1]
                let grade = info[1].components(separatedBy: " ")[0] //注意这是html
                let indexStart = res.range(of: "home.php?mod=space", range: start..<res.endIndex)!.upperBound
                let indexEnd = res.range(of: "</a>", range: indexStart..<res.endIndex)!.lowerBound
                let uid = Utils.getNum(from: String(res[indexStart..<indexEnd]))!
                
                print("name: \(name) grade: \(grade) uid:\(uid)")
                
                App.isLogin = true
                App.username = name
                App.uid = uid
                App.grade = grade
                
                //记住密码
                if let on = self?.remberSwitch.isOn, on {
                    print("save username and password")
                    Settings.username = name
                    Settings.password = self?.password
                    Settings.remberPassword = true
                } else {
                    Settings.remberPassword = false
                }
                
                vc = UIAlertController(title: "登陆成功", message: "欢迎[\(grade) \(name)]", preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                    self?.dismiss(animated: true, completion: nil)
                }))
            }
            
            // 取消loading
            self?.dismiss(animated: true, completion: {
                self?.present(vc, animated: true)
            })
        }
    }
    
    var loadingView: UIAlertController?
    
    func showLoadingView() {
        if loadingView == nil {
            loadingView = UIAlertController(title: "登陆中", message: "请稍后...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = .gray
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
