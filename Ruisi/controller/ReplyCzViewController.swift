//
//  ReplyCzViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/27.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 回复层主 页面
class ReplyCzViewController: UIViewController {
    
    // 必须设置要回复的对象
    var data: PostData!
    
    // 返回回帖是否成功
    var isSuccess = false
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var index: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var content: HtmlLabel!
    @IBOutlet weak var replyTextView: RitchTextView!
    private var progress: UIAlertController!
    
    
    private var postUrl: String?
    private lazy var parameters = [String:String]()
    
    private var canPost = false {
        didSet {
            self.navigationItem.rightBarButtonItem?.isEnabled =
                (postUrl != nil) && canPost
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canPost = false
        
        progress = UIAlertController(title: "回复中", message: "请稍后...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 13, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .gray
        loadingIndicator.startAnimating();
        progress.view.addSubview(loadingIndicator)
        progress.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        let color = UIColor(white: 0.97, alpha: 1.0)
        replyTextView.layer.borderColor = color.cgColor
        replyTextView.layer.borderWidth = 1.0
        replyTextView.layer.cornerRadius = 2.0
        replyTextView.showToolbar = true
        replyTextView.context = self
        replyTextView.placeholder = "回复内容"
        
        nickname.text = data.author
        time.text = data.time
        avatar.kf.setImage(with: Urls.getAvaterUrl(uid: data.uid))
        content.attributedText =  data.content
        index.text = data.index
        
        loadForm()
    }
    
    private func loadForm() {
        //1.根据replyUrl获得相关参数
        HttpUtil.GET(url: data.replyUrl!, params: nil, callback: { [weak self] (ok, res) in
            //print(res)
            if ok, let doc = try? HTML(html: res, encoding: .utf8) {
                //*[@id="postform"]
                if let url = doc.xpath("//*[@id=\"postform\"]").first?["action"] {
                    self?.postUrl = url
                    //*[@id="formhash"]
                    let inputs = doc.xpath("//*[@id=\"postform\"]/input")
                    for input in inputs {
                        self?.parameters[input["name"]!] = input["value"]!
                    }
                }
            }
            
            //处理未成功加载的楼层回复
            DispatchQueue.main.async { [weak self] in
                if self?.postUrl  == nil {
                    self?.canPost = false
                    let alert = UIAlertController(title: "加载失败", message: "是否重新加载?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "重新加载", style: .default, handler: { _ in
                        self?.dismiss(animated: true, completion: {
                            self?.loadForm()
                        })
                    }))
                    
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                } else {
                    self?.canPost = true
                }
            }
        })
    }
    
    // 回复层主
    @IBAction func postClick(_ sender: UIBarButtonItem) {
        guard var result = replyTextView.result, result.count > 0 else { return }
        replyTextView.resignFirstResponder()
        
        // 小尾巴
        if Settings.enableTail, let tail = Settings.tailContent, tail.count > 0 {
            result = result + "     " + tail
        }
        
        // 字数布丁
        let len = 13 - result.count
        if len > 0 {
            for _ in 0..<len {
                result += " "
            }
        }
        
        self.present(progress, animated: true, completion: nil)
        parameters["message"] = result
        //2. 正式评论层主
        HttpUtil.POST(url: postUrl!, params: parameters) { ok,res in
            var success = false
            var reason: String
            if ok {
                if res.contains("成功") || res.contains("层主") || res.contains("class=\"postlist\"") {
                    success = true
                    reason = "回复发表成功"
                } else if res.contains("您两次发表间隔") {
                    reason = "您两次发表间隔太短了,请稍后重试"
                } else if res.contains("主题自动关闭") {
                    reason = "此主题已关闭回复,无法回复"
                } else if res.contains("字符的限制") {
                    reason = "抱歉，您的帖子小于 13 个字符的限制"
                } else {
                    print(res)
                    reason = "由于未知原因发表失败"
                }
            } else {
                reason = "连接超时,请稍后重试"
            }
            
            DispatchQueue.main.async { [weak self] in
                //self?.replyView.isSending = false
                if !success {
                    self?.isSuccess = false
                    self?.showAlert(title: "回复失败", message: reason)
                } else {
                    self?.isSuccess = true
                    self?.progress.dismiss(animated: true) {
                        let alert = UIAlertController(title: "回复成功!", message: "是否需要返回", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "返回", style: .default) { action in
                            self?.dismiss(animated: true, completion: nil)
                        })
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        
    }
}
