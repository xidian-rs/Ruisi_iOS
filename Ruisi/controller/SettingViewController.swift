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
    @IBOutlet weak var tailContentTextVIew: UITextView!
    @IBOutlet weak var showZhidingSwitch: UISwitch!
    @IBOutlet weak var enableTailSwitch: UISwitch!

    private let defaultTail = "[size=1][color=Gray]-----来自[url=\(Urls.getPostUrl(tid: App.POST_ID))]手机睿思IOS版[/url][/color][/size]"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        showZhidingSwitch.isOn = Settings.showZhiding
        enableTailSwitch.isOn = Settings.enableTail
        tailContentTextVIew.text = Settings.tailContent
        tailContentTextVIew.isEditable = enableTailSwitch.isOn
        networkChangeSwitch.selectedSegmentIndex = App.isSchoolNet ? 1 : 0
        tailContentTextVIew.text = Settings.tailContent ?? defaultTail

        //CFBundleVersion
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "当前版本 V:\(version) Code:\(Bundle.main.infoDictionary?["CFBundleVersion"] as? Int ?? 1)"
        } else {
            versionLabel.text = "获取版本号出错"
        }

    }

    // 是否显示置顶帖
    @IBAction func showZhidingValueChange(_ sender: UISwitch) {
        print("hide zhiding \(sender.isOn)")
        Settings.showZhiding = sender.isOn
    }


    // 切换网络类型
    @IBAction func networkValueChange(_ sender: UISegmentedControl) {
        App.isSchoolNet = sender.selectedSegmentIndex == 1
        print("chnage network, is school net:\(App.isSchoolNet)")
    }


    // 是否允许小尾巴
    @IBAction func showTailValueChane(_ sender: UISwitch) {
        Settings.enableTail = sender.isOn
        tailContentTextVIew.isEditable = enableTailSwitch.isOn
    }

    // 小尾巴编辑结束
    override func viewWillDisappear(_ animated: Bool) {
        print("end edit tail")
        Settings.tailContent = tailContentTextVIew.text
        print("tail is \(tailContentTextVIew.text ?? "")")
    }


    @IBAction func viewOnGitHubClick(_ sender: UIButton) {
        if let url = URL(string: "https://github.com/freedom10086/Ruisi_Ios") {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func cleanCacheClick(_ sender: UIButton) {
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