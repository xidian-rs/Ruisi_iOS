//
//  MainViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kingfisher
import Kanna

// 首页 - 容器
class MainViewController: UITabBarController {
    
    var checkCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        App.isLogin = Settings.username != nil
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange), name: .flagsChanged, object: Network.reachability)
        
        checkNetwork()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    //selectedIndex 之前选择的位置
    // 切换tab
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
    
    @objc func networkChange(_ notification: Notification) {
        checkNetwork()
    }
    
    // 检查网络类型
    func checkNetwork() {
        guard let status = Network.reachability?.status else {
            return
        }
        
        print("====================")
        print("Reachability Summary")
        print("Status:", status)
        print("ConnectedToNetwork:", Network.reachability?.isConnectedToNetwork ?? "unknown")
        print("HostName:", Network.reachability?.hostname ?? "nil")
        print("Reachable:", Network.reachability?.isReachable ?? "nil")
        print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
        print("====================")
        
        App.isSchoolNet = (Network.reachability?.isReachableViaWiFi ?? false) ? (Network.reachability?.isReachable ?? false) : false
        checkCount = 0
        checkLogin()
    }
    
    
    //判断是否登陆 和 再次判断网络类型
    func checkLogin() {
        if checkCount >= 2 {
            DispatchQueue.main.async { [weak self] in
                if !(Network.reachability?.isConnectedToNetwork ?? false) {
                    self?.showAlert(title: "网络错误", message: "没有可用的网络连接，请打开网络连接!")
                } else {
                    self?.showAlert(title: "网络错误", message: "无法连接到服务器!")
                }
            }
            checkCount = 0
            return
        }
        
        checkCount += 1
        HttpUtil.PING(url: Urls.loginUrl, timeout: App.isSchoolNet ? 1 : 3) { (ok, res) in
            if !ok {
                App.isSchoolNet = !App.isSchoolNet
                self.checkLogin()
                return
            }
            
            self.checkCount = 0
            if res.contains("id=\"loginform\"") {
                App.isLogin = false
                print("schoolnet:\(App.isSchoolNet) login:\(App.isLogin)")
            } else if let doc = try? HTML(html: res, encoding: .utf8) {
                let messageNode = doc.xpath("/html/body/div[1]/p[1]").first
                let userNode = doc.xpath("/html/body/div[3]/div/a[1]").first
                let exitNode = doc.xpath("/html/body/div[3]/div/a[2]").first
                
                if messageNode != nil && userNode != nil && messageNode!.innerHTML!.contains("欢迎您回来") {
                    App.isLogin = true
                    App.uid = Utils.getNum(from: userNode!["href"] ?? "0")
                    App.username = userNode!.text
                    App.grade = messageNode!.text?.components(separatedBy: "，")[1].components(separatedBy: " ")[0]
                    App.formHash = Utils.getFormHash(from: exitNode?["href"])
                    print("schoolnet:\(App.isSchoolNet) login:\(App.isLogin) name:\(App.username ?? "") grade:\(App.grade ?? "") uid:\(App.uid ?? 0) formhash:\(App.formHash ?? "")")
                } else {
                    print("schoolnet:\(App.isSchoolNet) login:\(App.isLogin)")
                }
            } else {
                print("unknown login state")
            }
            
            if let forumVc = self.childViewControllers[0].childViewControllers[0] as? ForumsViewController, forumVc.loginState != App.isLogin {
                DispatchQueue.main.async {
                    forumVc.loginState = App.isLogin
                    forumVc.loadData(loginState: App.isLogin)
                }
            }
        }
    }
}
