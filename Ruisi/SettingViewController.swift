//
//  SettingViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/27.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {

    @IBOutlet weak var tailContentTextField: UITextField!
    @IBOutlet weak var showZhidingSwitch: UISwitch!
    @IBOutlet weak var enableTailSwitch: UISwitch!
    
    private let defaultTail = "[size=1][color=Gray]-----来自[url=\(Urls.getPostUrl(tid: App.POST_ID))]手机睿思IOS版[/url][/color][/size]"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showZhidingSwitch.isOn = Settings.showZhiding
        enableTailSwitch.isOn = Settings.enableTail
        tailContentTextField.text = Settings.tailContent
        tailContentTextField.isEnabled = enableTailSwitch.isOn
        
    }
    
    // 是否显示置顶帖
    @IBAction func showZhidingValueChange(_ sender: UISwitch) {
        print("hide zhiding \(sender.isOn)")
        Settings.showZhiding = sender.isOn
    }

    
    // 切换网络类型
    @IBAction func networkValueChange(_ sender: UISegmentedControl) {
        // todo
    }
    
    
    // 是否允许小尾巴
    @IBAction func showTailValueChane(_ sender: UISwitch) {
        Settings.enableTail = sender.isOn
        tailContentTextField.isEnabled = enableTailSwitch.isOn
    }
    
    
    // 小尾巴编辑结束
    @IBAction func tailContentEditEnd(_ sender: UITextField) {
        
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
