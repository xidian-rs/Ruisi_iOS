//
//  SettingViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/27.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 设置
class SettingViewController: UITableViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var networkChangeSwitch: UISegmentedControl!
    @IBOutlet weak var networkNoticeLabel: UILabel!
    @IBOutlet weak var tailContentTextVIew: UITextView!
    @IBOutlet weak var showZhidingSwitch: UISwitch!
    @IBOutlet weak var enableTailSwitch: UISwitch!
    @IBOutlet weak var postRenderTypeSwitch: UISwitch!
    @IBOutlet weak var rencentVistForumSwitch: UISwitch!
    
    private let defaultTail = "[size=1][color=Gray]-----来自[url=\(Urls.getPostUrl(tid: App.POST_ID))]手机睿思IOS版[/url][/color][/size]"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        showZhidingSwitch.isOn = Settings.showZhiding
        enableTailSwitch.isOn = Settings.enableTail
        postRenderTypeSwitch.isOn = Settings.postContentRenderType
        rencentVistForumSwitch.isOn = Settings.closeRecentVistForum
        tailContentTextVIew.text = Settings.tailContent
        tailContentTextVIew.isEditable = enableTailSwitch.isOn
        tailContentTextVIew.text = Settings.tailContent ?? defaultTail
        
        //CFBundleVersion
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "当前版本:\(version) Build:\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "1")"
        } else {
            versionLabel.text = "获取版本号出错"
        }
        
        networkChangeSwitch.selectedSegmentIndex = Settings.networkType
        setNetworkTypeText()
    }
    
    private func setNetworkTypeText() {
        if networkChangeSwitch.selectedSegmentIndex == 0 {
            networkNoticeLabel.text = "自动判断类型为:\(App.isSchoolNet ? "校园网" : "外网")"
        } else if networkChangeSwitch.selectedSegmentIndex == 1 {
            networkNoticeLabel.text = "当前选择:外网"
        } else {
            networkNoticeLabel.text = "当前选择:校园网"
        }
    }
    
    // 是否显示最近常逛的功能
    @IBAction func closeRencentVistForum(_ sender: UISwitch) {
        print("closeRencentVistForum \(sender.isOn)")
        Settings.closeRecentVistForum = sender.isOn
    }
    
    
    // 是否显示置顶帖
    @IBAction func showZhidingValueChange(_ sender: UISwitch) {
        print("hide zhiding \(sender.isOn)")
        Settings.showZhiding = sender.isOn
    }
    
    
    // 切换网络类型
    @IBAction func networkValueChange(_ sender: UISegmentedControl) {
        Settings.networkType = sender.selectedSegmentIndex
        setNetworkTypeText()
        
        if sender.selectedSegmentIndex == 1 {
            showAlert(title: "提示", message: "网络类型已切换为外网(校园网外网均可访问,不免流量)")
            App.isSchoolNet = false
        } else if sender.selectedSegmentIndex == 2 {
            showAlert(title: "提示", message: "网络类型已切换为校园网,外网无法访问(如4G流量)")
            App.isSchoolNet = true
        } else {
            showAlert(title: "提示", message: "网络类型已切换为自动判断, 重启APP后开始生效！")
        }

        print("chnage network, auro:\(sender.selectedSegmentIndex == 0) is school net:\(App.isSchoolNet)")
    }
    
    // 正文渲染控件 UILabel or UITextView
    @IBAction func postContentRenderChange(_ sender: UISwitch) {
        Settings.postContentRenderType = sender.isOn
    }
    
    // 是否允许小尾巴
    @IBAction func showTailValueChane(_ sender: UISwitch) {
        Settings.enableTail = sender.isOn
        tailContentTextVIew.isEditable = enableTailSwitch.isOn
    }
    
    // 小尾巴编辑结束
    override func viewWillDisappear(_ animated: Bool) {
        Settings.tailContent = tailContentTextVIew.text
    }
    
    
    @IBAction func viewOnGitHubClick(_ sender: UIButton) {
        if let url = URL(string: "https://github.com/freedom10086/Ruisi_Ios") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func cleanCacheClick(_ sender: UIButton) {
        showAlert(title: "还没做", message: "待以后完成，欢迎提供你的建议")
    }
    
}
