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
    var isAutoNetworkType = (Settings.networkType == 0)
    
    var schoolNetChecking = false
    var outNetChecking = false
    
    var schoolNetSuccess = false
    var outNetSuccess = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isAutoNetworkType {
            NotificationCenter.default.addObserver(self, selector: #selector(networkChange), name: .flagsChanged, object: Network.reachability)
        }
        
        checkNetwork()
        
        if isAutoNetworkType {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                // delay 500ms if all net work is still not ok set net work type out
                if let this = self, this.isAutoNetworkType, !this.schoolNetSuccess, !this.outNetSuccess {
                    print("delay 500ms temp set net to out net...")
                    App.isSchoolNet = false
                }
            }
        }
        
    }
    
    deinit {
        if isAutoNetworkType {
            NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        }
    }
    
    var lastSelectItem: UITabBarItem?
    
    //selectedIndex 之前选择的位置
    // 切换tab
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if lastSelectItem != nil && item != lastSelectItem {
            lastSelectItem = item
        } else {
            if lastSelectItem == nil {
                lastSelectItem = item
            }
            if let topableVc = self.selectedViewController?.children[0] as? ScrollTopable {
                topableVc.scrollTop()
            }
        }
    }
    
    @objc func networkChange(_ notification: Notification) {
        print("network change...")
        checkNetwork()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            print("start update forums ...")
            for navVc in self?.children ?? [] {
                if let vc = navVc as? UINavigationController, let dest = vc.children.first as? ForumsViewController {
                    dest.networkChange()
                }
            }
        }
    }
    
    // 检查网络类型
    func checkNetwork() {
        print("======checkNetwork======")
        
        checkCount = 0
        schoolNetSuccess = false
        outNetSuccess = false
        
        if Settings.networkType == 0 {
            // auto network type
            print("Reachability Summary")
            print("Status:", Network.reachability?.status ?? "unknown")
            print("ConnectedToNetwork:", Network.reachability?.isConnectedToNetwork ?? "unknown")
            print("HostName:", Network.reachability?.hostname ?? "nil")
            print("Reachable:", Network.reachability?.isReachable ?? "nil")
            print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
            print("====================")
            
            App.isSchoolNet = (Network.reachability?.isReachableViaWiFi ?? false) ? (Network.reachability?.isReachable ?? false) : false
            print("临时设置网络类型为:\(App.isSchoolNet ? "校园网" : "校外网")")
            if App.isSchoolNet {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.checkLogin(isSchoolNet: true)
                }
            } else {
                // not school net
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.checkLogin(isSchoolNet: false)
                }
            }
        } else {
            // manul network type
            App.isSchoolNet = (Settings.networkType == 2)
            print("手动设置网络类型为:\(App.isSchoolNet ? "校园网" : "校外网")")
            checkCount = 1
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.checkLogin(isSchoolNet: App.isSchoolNet)
            }
        }
    }
    
    
    //判断是否登陆 和 再次判断网络类型
    func checkLogin(isSchoolNet: Bool) {
        if isSchoolNet && schoolNetChecking {
            print("checking... no need check school net..")
            return
        }
        
        if !isSchoolNet && outNetChecking {
            print("checking... no need check out net..")
            return
        }
        
        if isSchoolNet {
            schoolNetChecking = true
        } else {
            outNetChecking = true
        }
        
        if checkCount >= 2 {
            DispatchQueue.main.async { [weak self] in
                if self?.isAutoNetworkType ?? true {
                    if !(Network.reachability?.isConnectedToNetwork ?? false) {
                        self?.showAlert(title: "网络错误", message: "没有可用的网络连接，请打开网络连接!")
                    } else {
                        self?.showAlert(title: "网络错误", message: "无法连接到服务器!估计是睿思服务器又崩溃了 囧rz")
                    }
                } else {
                    self?.showAlert(title: "网络错误", message: "无法连接到服务器!请检查网络连接或者网络设置,你当前手动设置网络类型为:\(App.isSchoolNet ? "校园网" : "外网")！")
                }
                
            }
            checkCount = 0
            return
        }
        
        let url: String
        if isSchoolNet {
            url = Urls.checkLoginUrlInner
        } else {
            url = Urls.checkLoginUrlOut
        }
        checkCount += 1
        HttpUtil.PING(url: url, timeout: App.isSchoolNet ? 1.5 : 2) { [weak self] (ok, res) in
            guard let this = self else { return }
            if isSchoolNet {
                this.schoolNetChecking = false
            } else {
                this.outNetChecking = false
            }
            
            if !ok {
                if this.isAutoNetworkType {
                    this.checkLogin(isSchoolNet: !isSchoolNet)
                } else {
                    // manul mode
                    this.checkCount += 2
                    this.checkLogin(isSchoolNet: !isSchoolNet)
                }
                return
            }
            
            if isSchoolNet {
                // school net success
                this.schoolNetSuccess = true
                App.isSchoolNet = true
            } else {
                // out net success
                if !this.schoolNetSuccess {
                    this.outNetSuccess = true
                    App.isSchoolNet = false
                } else {
                    // but school net already success ignore
                    this.outNetSuccess = true
                    print("ignore out net success, school net is already success")
                    if App.isLogin {
                        // school net is already login not to check login state
                        return
                    }
                }
            }
        
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
        }
    }
}
