//
//  MainViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kingfisher

class MainViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        checkUpdate()
    }
    
    //selectedIndex 之前选择的位置
    
    // 切换tab
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tab position : \(selectedIndex)")
    }
    
    // 第一次进入首页检查登陆状态
    func checkUpdate() {
        //TODO
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
