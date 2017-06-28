//
//  MyViewTableController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class MyViewController: UIViewController,UITableViewDelegate,
    UITableViewDataSource,UINavigationControllerDelegate{

    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var avaterImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usergradeLabel: UILabel!
    
    
    var images = ["ic_refresh_48pt","ic_info_48pt","ic_share_48pt","ic_favorite_48pt","ic_settings_48pt"]
    var titles = ["签到中心","关于本程序","分享手机睿思","到商店评分","设置"]

    // 创建的时候的登陆状态
    var isLogin: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            usernameLabel.text = App.username
            usergradeLabel.text = App.grade
            
            Settings.getAvater(uid: App.uid!) { data in
                DispatchQueue.main.async { [weak self] in
                    if let d = data {
                        self?.avaterImage.image = UIImage(data: d)
                    }
                }
            }
        }else{
            usernameLabel.text = "点击头像登陆"
            avaterImage.image = #imageLiteral(resourceName: "placeholder")
        }
    }
    
    
    // 手势处理函数
    func tapHandler(sender:UITapGestureRecognizer) {
        if let v = sender.view {
            switch v {
            case avaterImage:
                print("avater click")
                if App.isLogin{
                    //detail
                }else{
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
        print(viewController)
        
        // 判断要显示的控制器是否是自己
        if let _ = viewController as? MyViewController {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }else{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let imageview  = cell.viewWithTag(1) as! UIImageView
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
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "signViewController")
            self.show(dest!, sender: self)
            break
        case 1:
            //about
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "aboutViewController")
            self.show(dest!, sender: self)
        case 2:
            //share
            let activityController = UIActivityViewController(activityItems: ["分享:手机睿思IOS版[\(Urls.getPostUrl(tid: App.POST_ID))]"], applicationActivities: nil)
            // should be the rect that the pop over should anchor to
            activityController.popoverPresentationController?.sourceRect = view.frame
            activityController.popoverPresentationController?.sourceView = view
            activityController.popoverPresentationController?.permittedArrowDirections = .any
            // present the controller
            present(activityController, animated: true, completion: nil)
            break
        case 3:
            //evaluate
            let ac = UIAlertController(title: "到商店评分", message: "暂时不准备上架商店,无法评分(99美刀～～)", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(ac, animated: true)
        case 4:
            //setting
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "settingViewController")
            self.show(dest!, sender: self)
        default:
            break
        }
    }
    
    
    // 转场之前的检查
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "toHistoryController":
            print("to history")
        case "toStarController":
            print("to star")
        case "toFriendController":
            print("to friend")
        case "toMyPostsController":
            print("to my posts")
        default:
            break
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
