//
//  AboutViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import MessageUI
import Kanna

// 关于页面
class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func replyClick(_ sender: Any) {
        let destVc = self.storyboard?.instantiateViewController(withIdentifier: "PostViewController") as! PostViewController
        destVc.tid = App.POST_ID
        self.show(destVc, sender: self)
    }
    
    @IBAction func issueClick(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://github.com/freedom10086/Ruisi_Ios/issues")!)
    }
    
    @IBAction func sourceCodeClick(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://github.com/freedom10086/Ruisi_Ios")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        let button1 = UIBarButtonItem(title: "反馈", style: .done, target: self, action: #selector(feedBackClick))
        self.navigationItem.rightBarButtonItem = button1
        
        //CFBundleVersion
        if let version = getVersionNum() {
            versionLabel.text = "当前版本 version: \(version)"
        } else {
            versionLabel.text = "获取版本号出错"
        }
        
        let versionCode = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "1"
        print("current versionCode:\(versionCode)")
    }
    
    private func getVersionNum() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    private func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: Error) {
        switch result {
        case .sent:
            print("Mail sent")
            alert(title: "反馈成功", message: "感谢你的反馈,开发者会看到你的邮件", bdy: "好")
            
        default:
            print("Mail sent failure: \(error.localizedDescription)")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func feedBackClick() {
        let emailTitle = "手机睿思(iOS)反馈\(Settings.username != nil ? (" -by:" + Settings.username!) : "") -ver:\(getVersionNum() ?? "unknown")"
        let messageBody = ""
        let toRecipents = ["2351386755@qq.com"]
        
        if MFMailComposeViewController.canSendMail() {
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            mc.setToRecipients(toRecipents)
            
            self.present(mc, animated: true, completion: nil)
        } else {
            alert(title: "无法反馈", message: "没有可用的邮件客户端", bdy: "好的")
        }
    }
    
    
    func alert(title: String?, message: String?, bdy: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: bdy, style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        
        let delayTime = DispatchTime.now().uptimeNanoseconds + 2 * NSEC_PER_SEC
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: delayTime)) {
            [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
