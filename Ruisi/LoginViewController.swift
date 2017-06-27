//
//  LoginViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var remberSwitch: UISwitch!
    
    
    var username: String {
        return usernameTextField.text ?? ""
    }
    
    var password: String {
        return passwordTextField.text ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("login controller")
        
        if Settings.remberPassword {
            remberSwitch.isOn = true
            usernameTextField.text = Settings.username
            passwordTextField.text = Settings.password
        }
    }
    
    
    @IBAction func cencelClick(_ sender: Any) {
        // self.dismiss(animated: true, completion: nil)
        presentingViewController?.dismiss(animated: true)
    }
    
    func alert(title:String? = "登陆错误", message: String) {
        let vc = UIAlertController(title: "登陆错误", message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil ))
        self.present(vc, animated: true)
    }
    
    @IBAction func loginClick(_ sender: UIBarButtonItem) {
        if username.characters.count <= 0 {
            alert(message: "用户名不能为空")
            return
        }
        
        if password.characters.count <= 0 {
            alert(message: "密码不能为空")
            return
        }
        
        showLoadingView()
        HttpUtil.GET(url: Urls.loginUrl, params: nil) { ok, res in
            if ok {
                if res.contains("欢迎您回来"){
                    print("cookie is still work login ok")
                    self.loginResult(isok: true,res: res)
                    return
                }
                
                if let start = res.endIndex(of: "action=\""){
                    let substr = res.substring(from: start)
                    let end = substr.index(of: "\"")
                    let loginUrl = substr.substring(to: end!)
                    
                    let params = "username=\(self.username)&password=\(self.password)&fastloginfield=username&cookietime=2592000"
                    
                    HttpUtil.POST(url: loginUrl, params: params, callback: { ok, res in
                        print("post ok")
                        if ok && res.contains("欢迎您回来"){
                            self.loginResult(isok: true,res: res)
                        }else {
                            self.loginResult(isok: false,res: "账号或密码错误")
                        }
                    })
                } else {
                    self.loginResult(isok: false,res: "未知错误")
                }
            }else {
                self.loginResult(isok: false,res: "网络错误")
            }
        }
    }
    
    var loadingView:UIAlertController?
    
    func showLoadingView() {
        if loadingView==nil{
            loadingView = UIAlertController(title: "登陆中", message: "请稍后...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = .gray
            loadingIndicator.startAnimating()
            loadingView!.view.addSubview(loadingIndicator)
        }
        
        present(loadingView!, animated: true, completion: nil)
    }
    
    func hideLoadingView() {
        dismiss(animated: true, completion: nil)
    }
    
    func loginResult(isok: Bool = false,res: String) {
        print("=== login result \(isok) ===")
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingView()
            if !isok {
                self?.alert(message: res)
            }
        }
        
        if isok {
            let start = res.range(of: "欢迎您回来")!.upperBound
            let end = res.range(of: "</p>", range: start ..< res.endIndex)!.lowerBound
            let info = res.substring(with: start ..< end).components(separatedBy: "，")
            let name = info[1].components(separatedBy: " ")[1]
            let grade = info[1].components(separatedBy: " ")[0] //注意这是html
            let indexStart =  res.range(of: "home.php?mod=space",range: start ..< res.endIndex)!.upperBound
            let indexEnd = res.range(of: "</a>", range: indexStart ..< res.endIndex)!.lowerBound
            let uid = Utils.getNum(from: res.substring(with: indexStart ..< indexEnd))!
            
            print("name: \(name) grade: \(grade) uid:\(uid)")
            
            App.isLogin = true
            App.username = name
            App.uid = uid
            App.grade = grade
            
            //记住密码
            if remberSwitch.isOn {
                print("save username and password")
                Settings.username = name
                Settings.password = password
            }
            
            Settings.remberPassword = remberSwitch.isOn
            let vc = UIAlertController(title: "登陆成功", message: "欢迎[\(grade) \(name)]", preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                self.dismiss(animated: true, completion: nil)
            }))
            
            self.present(vc, animated: true)
        }
    }
    
    // 处理软键盘
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
