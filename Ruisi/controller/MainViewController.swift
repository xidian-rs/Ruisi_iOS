//
//  MainViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kingfisher

// 首页 - 容器
class MainViewController: UITabBarController {
    
    var checkCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
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
        print("====================")
        print("Reachability Summary")
        print("Status:", Network.reachability?.status ?? "unknown")
        print("ConnectedToNetwork:", Network.reachability?.isConnectedToNetwork ?? "unknown")
        print("HostName:", Network.reachability?.hostname ?? "nil")
        print("Reachable:", Network.reachability?.isReachable ?? "nil")
        print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
        print("====================")
        
        App.isSchoolNet = (Network.reachability?.isReachableViaWiFi ?? false) ? (Network.reachability?.isReachable ?? false) : false
        checkCount = 0
        print("临时设置网络类型为:\(App.isSchoolNet ? "校园网" : "校外网")")
        checkLogin()
    }
    
    
    //判断是否登陆 和 再次判断网络类型
    func checkLogin() {
        if checkCount >= 2 {
            DispatchQueue.main.async { [weak self] in
                if !(Network.reachability?.isConnectedToNetwork ?? false) {
                    self?.showAlert(title: "网络错误", message: "没有可用的网络连接，请打开网络连接!")
                } else {
                    self?.showAlert(title: "网络错误", message: "无法连接到服务器!估计是睿思服务器又崩溃了 囧rz")
                }
            }
            checkCount = 0
            return
        }
        
        checkCount += 1
        HttpUtil.PING(url: Urls.checkLoginUrl, timeout: App.isSchoolNet ? 1 : 3) { (ok, res) in
            if !ok {
                App.isSchoolNet = !App.isSchoolNet
                self.checkLogin()
                return
            }
        
            self.checkCount = 0
            if res.contains("id=\"loginform\"") {
                Settings.uid = nil
                print("网络类型:\(App.isSchoolNet) 是否登陆:\(App.isLogin)")
            } else if res.contains("欢迎您回来") {
                let start = res.range(of: "{'")!.upperBound
                let end = res.range(of: "'}", range: start..<res.endIndex)!.lowerBound
                //{'username':'FREEDOM_1','usergroup':'西电托儿所','uid':'262789'}
                let dic = res[start..<end].replacingOccurrences(of: "'", with: "").components(separatedBy: ",")
                for item in dic {
                    let key = item.components(separatedBy: ":")[0]
                    let val = item.components(separatedBy: ":")[1]
                    if key == "username" {
                        Settings.username = val
                    } else if key == "usergroup" {
                        Settings.grade = val
                    } else if key == "uid" {
                        Settings.uid = Utils.getNum(from: val)
                    }
                }
                
                print("网络类型:\(App.isSchoolNet) 是否登陆:\(App.isLogin) uid:\(Settings.uid ?? 0) name:\(Settings.username ?? "") grade:\(Settings.grade ?? "")")
            } else {
                print("网络类型:\(App.isSchoolNet) 未知登陆状态")
            }
            
            if let forumVc = self.childViewControllers[0].childViewControllers[0] as? ForumsViewController, forumVc.loadedUid != Settings.uid {
                DispatchQueue.main.async {
                    forumVc.loadedUid = Settings.uid
                    forumVc.loadData(uid: forumVc.loadedUid)
                }
            }
        }
    }
}
