//
//  MyViewTableController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import StoreKit

// 首页 - 我
class MyViewController: UIViewController, UITableViewDelegate,
UITableViewDataSource, UINavigationControllerDelegate {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var avaterImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usergradeLabel: UILabel!
    @IBOutlet weak var headBgView: UIView!
    
    var images = ["ic_refresh_48pt", "ic_color_lens_48pt", "ic_info_48pt", "ic_share_48pt", "ic_favorite_48pt", "ic_settings_48pt"]
    var titles = ["签到中心", "主题设置", "关于本程序", "分享手机睿思","五星好评", "设置"]
    
    // 创建的时候的登陆状态
    var isLogin: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headBgView.backgroundColor = ThemeManager.currentPrimaryColor
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        //获得导航栏控制权
        self.navigationController?.delegate = self
        
        
        myTableView.dataSource = self
        myTableView.delegate = self
        
        avaterImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandler(sender:))))
        
        isLogin = App.isLogin
        updateUi()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if App.isLogin != isLogin {
            isLogin = App.isLogin
            updateUi()
        }
    }
    
    private func updateUi() {
        usergradeLabel.isHidden = !isLogin
        if isLogin {
            usernameLabel.text = Settings.username
            usergradeLabel.text = Settings.grade
            
            if let uid = Settings.uid {
                Settings.getAvater(uid: uid) { data in
                    DispatchQueue.main.async { [weak self] in
                        if let d = data {
                            self?.avaterImage.image = UIImage(data: d)
                        }
                    }
                }
            }
        } else {
            usernameLabel.text = "点击头像登陆"
            avaterImage.image = #imageLiteral(resourceName:"placeholder")
        }
    }
    
    
    // 手势处理函数
    @objc func tapHandler(sender: UITapGestureRecognizer) {
        if let v = sender.view {
            switch v {
            case avaterImage:
                if App.isLogin {
                    self.performSegue(withIdentifier: "myProvileSegue", sender: nil)
                } else {
                    //login
                    let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
                    self.present(dest!, animated: true, completion: nil)
                }
            default:
                break
            }
        }
    }
    
    
    //控制显示隐藏导航栏
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // 判断要显示的控制器是否是自己
        if let _ = viewController as? MyViewController {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let imageview = cell.viewWithTag(1) as! UIImageView
        let label = cell.viewWithTag(2) as! UILabel
        
        
        imageview.image = UIImage(named: images[indexPath.row])
        
        label.text = titles[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //["签到中心","关于本程序","分享手机睿思","到商店评分","设置"]
        switch indexPath.row {
        case 0:
            //sign
            if !App.isSchoolNet {
                let alert = UIAlertController(title: "提示", message: "签到功能只在校园网环境下有效,你当前的网络环境不是校园网", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else if !App.isLogin {
                showLoginAlert()
            } else {
                let dest = self.storyboard?.instantiateViewController(withIdentifier: "signViewController")
                self.show(dest!, sender: self)
            }
            break
        case 1:
            //theme
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "themeViewController")
            self.show(dest!, sender: self)
        case 2:
            //about
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "aboutViewController")
            self.show(dest!, sender: self)
        case 3:
            //share
            let activityController = UIActivityViewController(activityItems: ["分享:手机睿思iOS版\nApp Store 地址: https://itunes.apple.com/cn/app/\(App.APP_ID)"], applicationActivities: nil)
            // should be the rect that the pop over should anchor to
            activityController.popoverPresentationController?.sourceRect = view.frame
            activityController.popoverPresentationController?.sourceView = view
            activityController.popoverPresentationController?.permittedArrowDirections = .any
            // present the controller
            present(activityController, animated: true, completion: nil)
            break
        case 4:
            let ac = UIAlertController(title: "五星好评", message: "你们的支持是我最大的动力！", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default, handler: {(alertAc) in
                if #available(iOS 10.3, *) {
                    SKStoreReviewController.requestReview()
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/\(App.APP_ID)?action=write-review")!)
                }
            }))
            ac.addAction(UIAlertAction(title: "残忍拒绝", style: .destructive, handler: nil))
            present(ac, animated: true)
        case 5:
            //setting
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "settingViewController")
            self.show(dest!, sender: self)
        default:
            break
        }
    }
    
    func showLoginAlert() {
        let alert = UIAlertController(title: "需要登陆", message: "你需要登陆才能执行此操作", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "登陆", style: .default, handler: { (alert) in
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
            self.present(dest!, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // 转场之前的检查
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "toStarController", "toFriendController", "toMyPostsController":
            if !App.isLogin {
                showLoginAlert()
                return false
            }
            break
        default:
            break
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UserDetailViewController {
            dest.uid = Settings.uid!
            dest.username = Settings.username!
        }
    }
}
