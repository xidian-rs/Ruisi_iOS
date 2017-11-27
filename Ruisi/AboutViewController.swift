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

class AboutViewController: UIViewController,MFMailComposeViewControllerDelegate{
    
    @IBOutlet weak var aboutText: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var checkVersionLabel: UILabel!
    
    let ss = "<b>西电睿思手机客户端</b><br />功能不断完善中，bug较多还请多多反馈......<br />" +
        "bug反馈:<br />" +
        "1.到 <a href=\"forum.php?mod=viewthread&tid=\(App.POST_ID)&mobile=2\">本帖</a> 回复<br />" +
        "2.本站 <a href=\"home.php?mod=space&uid=252553&do=profile&mobile=2\">@谁用了FREEDOM</a><br />" +
        "3.本站 <a href=\"home.php?mod=space&uid=261098&do=profile&mobile=2\">@wangfuyang</a><br />" +
    "4.github提交 <a href=\"https://github.com/freedom10086/Ruisi/issues\">点击这儿<br /></a><br />";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button1 = UIBarButtonItem(title: "反馈", style: .done, target: self, action: #selector(feedBackClick))
        self.navigationItem.rightBarButtonItem  = button1
        
        aboutText.numberOfLines = 0
        aboutText.lineBreakMode = .byWordWrapping
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let attributeStr = self.stringFromHtml(string: self.ss) {
                DispatchQueue.main.async {
                    self.aboutText.attributedText = attributeStr
                }
            }else{
                DispatchQueue.main.async {
                    self.title = self.ss
                }
            }
            
        }
        
        //CFBundleVersion
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "当前版本 version: \(version)"
        }else {
            versionLabel.text = "获取版本号出错"
        }
        
        let versionCode = Bundle.main.infoDictionary?["CFBundleVersion"] as? Int ?? 1
        HttpUtil.GET(url: Urls.checkUpdate, params: nil) { ok, res in
            var versionText: String
            if ok {
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    if let i = doc.title?.endIndex(of: "code"){
                        if let version = Utils.getNum(from: (String(doc.title![i...]))) {
                            print("server version \(version)")
                            if versionCode < version {
                                versionText = "已经有新的版本更新,服务器版本 V\(version)"
                            } else {
                                versionText = "当前已是最新版本"
                            }
                            
                            DispatchQueue.main.async {
                                [weak self] in
                                self?.checkVersionLabel.text = versionText
                            }
                            
                            return
                        }
                    }
                }
                
                versionText = "从服务器获得版本号失败"
            }else {
                versionText = "检查更新失败"
            }
            
            
            DispatchQueue.main.async {
                [weak self] in
                self?.checkVersionLabel.text = versionText
            }
        }
    }
    
    
    private func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:Error) {
        switch result {
        case .sent:
            print("Mail sent")
            alert(title: "反馈成功", message: "感谢你的反馈,开发者会看到你的邮件", bdy: "好")
            
        default :
            print("Mail sent failure: \(error.localizedDescription)")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func feedBackClick() {
        print("feed back")
        
        let emailTitle = "Feedback"
        let messageBody = "Feature request or bug report?"
        let toRecipents = ["friend@stackoverflow.com"]
        
        if MFMailComposeViewController.canSendMail() {
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            mc.setToRecipients(toRecipents)
            
            self.present(mc, animated: true, completion: nil)
        } else {
            alert(title: "无法反馈", message: "没有可用的邮件客户端", bdy:"好的")
        }
    }
    
    
    func alert(title: String?, message: String?, bdy:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: bdy, style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        
        let delayTime = DispatchTime.now().uptimeNanoseconds + 2 * NSEC_PER_SEC
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds:delayTime)) {
            [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    
    private func stringFromHtml(string: String) -> NSAttributedString? {
        do {
            let data = string.data(using: String.Encoding.unicode, allowLossyConversion: true)
            if let d = data {
                let str = try NSMutableAttributedString(data: d, options: [
                    NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],documentAttributes: nil)
                str.addAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: CGFloat(18)) as Any], range: NSRange(location: 0, length: str.length))
                return str
            }
        } catch {
            print(error)
        }
        return nil
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
