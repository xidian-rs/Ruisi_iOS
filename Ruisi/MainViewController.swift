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

class MainViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkNetwork()
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange), name: .flagsChanged, object: Network.reachability)
    }
    
    //selectedIndex 之前选择的位置
    // 切换tab
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
    
    
    // 检查网络类型
    func checkNetwork() {
        guard let status = Network.reachability?.status else {return}
        print("====================")
        print("Reachability Summary")
        print("Status:", status)
        print("HostName:", Network.reachability?.hostname ?? "nil")
        print("Reachable:", Network.reachability?.isReachable ?? "nil")
        print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
        print("====================")
        
        App.isSchoolNet = Network.reachability?.isReachable ?? false
        checkLogin()
    }
    
    @objc func networkChange(_ notification: Notification) {
        checkNetwork()
    }
    
    //判断是否登陆
    func checkLogin() {
        HttpUtil.GET(url: Urls.loginUrl, params: nil) { (ok, res) in
            if res.contains("id=\"loginform\"") {
                App.isLogin = false
            }else if let doc = try? HTML(html: res, encoding: .utf8) {
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
                }
            }else {
                print("unknown login state")
            }
            
            if let forumVc = self.childViewControllers[0].childViewControllers[0] as? ForumsViewController,forumVc.loginState != App.isLogin {
                DispatchQueue.main.async {
                    forumVc.loginState = App.isLogin
                    forumVc.loadData(loginState: App.isLogin)
                }
            }
        }
    }
}
