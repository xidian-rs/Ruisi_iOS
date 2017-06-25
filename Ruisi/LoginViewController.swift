//
//  LoginViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,UINavigationControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // 判断要显示的控制器是否是自己
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func usernameInputEnd(_ sender: UITextField) {
        print("end",sender.text ?? "")
    }
    
    @IBAction func usernameInputChange(_ sender: UITextField) {
        print("change",sender.text ?? "")
    }
    
    @IBAction func cencelClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func loginClick(_ sender: UIBarButtonItem) {
        showLoadingView()
        
        HttpUtil.GET(url: Urls.loginUrl, params: nil) { ok, res in
            print(res)
            if ok {
                if res.contains("欢迎您回来"){
                    self.loginResult(isok: true)
                    return
                }
                
                if let start = res.endIndex(of: "action=\""){
                    let substr = res.substring(from: start)
                    let end = substr.index(of: "\"")
                    let loginUrl = substr.substring(to: end!)
                
                    let params = "username=谁用了FREEDOM&password=justice&fastloginfield=username&cookietime=2592000"
                    HttpUtil.POST(url: loginUrl, params: params, callback: { ok, res in
                        if ok && res.contains("欢迎您回来"){
                            print(res)
                            self.loginResult(isok: true)
                            return
                        }else{
                            self.loginResult()
                        }
                    })
                    
                    return
                }
            
            }
            
            self.loginResult()
            return
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
    
    func loginResult(isok: Bool = false) {
        hideLoadingView()
        
        print(isok)
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
