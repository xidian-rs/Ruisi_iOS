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
    
    
    var images = ["ic_refresh_48pt","ic_info_48pt","ic_share_48pt","ic_favorite_48pt","ic_settings_48pt"]
    var titles = ["签到中心","关于本程序","分享手机睿思","到商店评分","设置"]

    override func viewDidLoad() {
        super.viewDidLoad()

        //获得导航栏控制权
        self.navigationController?.delegate = self
        
        myTableView.dataSource = self
        myTableView.delegate = self
        
        let tap =  UITapGestureRecognizer(target: self, action: #selector(MyViewController.handleAvaterTap))
        avaterImage.addGestureRecognizer(tap)
    }
    
    func handleAvaterTap() {
        print("avater click")
        if isLogin{
            //detail
        }else{
            //login
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginView") as? LoginViewController
            self.present(dest!, animated: true, completion: nil)
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
    }



    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
