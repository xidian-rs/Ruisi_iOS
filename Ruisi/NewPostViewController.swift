//
//  NewPostViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/3.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

class NewPostViewController: UIViewController,ForumSelectDelegate {
    
    func selectFid(fid: Int, name: String) {
        print("fid \(fid) name \(name)")
        
        if self.fid != fid {
            self.name = name
            self.fid = fid
            selectedBtn.setTitle(name, for: .normal)
            fidChange(fid: fid)
        }
    }
    
    var fid: Int?
    var typeId:String?
    var name: String?
    var typeIds = [KeyValueData<String,String>]()
    var progress: UIAlertController!
    
    @IBOutlet weak var selectedBtn: UIButton!
    @IBOutlet weak var subSeletedBtn: UIButton!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var contentInput: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let color = UIColor(white: 0.9, alpha: 1.0)
        contentInput.layer.borderColor = color.cgColor
        contentInput.layer.borderWidth = 1.0
        contentInput.layer.cornerRadius =  5.0
        
        subSeletedBtn.isHidden = true
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(postClick))]
        
        if let f = fid {
            selectedBtn.setTitle(name, for: .normal)
            fidChange(fid: f)
        }
        
        progress = UIAlertController(title: "发帖中", message: "请稍后...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 13, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = .gray
        loadingIndicator.startAnimating();
        progress.view.addSubview(loadingIndicator)
        progress.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    }
    
    func checkInput() -> Bool {
        var reason:String?
        if fid == nil {
            reason = "你还没有选择分区"
        }else if titleInput.text == nil || titleInput.text?.count == 0 {
            reason = "标题不能为空"
        }else if contentInput.text == nil || contentInput.text.count == 0 {
            reason = "内容不能为空"
        }
        
        
        if reason != nil {
            let alert = UIAlertController(title: "提示", message: reason, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
    func fidChange(fid:Int) {
        typeIds = []
        typeId = nil
        subSeletedBtn.isHidden = true
        
        HttpUtil.GET(url: Urls.newPostUrl(fid: fid), params: nil) { (ok, res) in
            if ok && self.fid == fid {
                if let doc = try? HTML(html: res, encoding: .utf8){
                    let nodes =  doc.css("#typeid option")
                    for node in nodes {
                        if !node.text!.contains("选择主题分类") {
                            self.typeIds.append(KeyValueData(key: node["value"]!, value: node.text!))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if self.typeIds.count > 0 {
                        self.typeId = self.typeIds[0].key
                        self.subSeletedBtn.isHidden = false
                        self.subSeletedBtn.setTitle(self.typeIds[0].value, for: .normal)
                    }
                }
            }
        }
    }
    
    
    @IBAction func chooseSubForumClick(_ sender: UIButton) {
        let sheet =  UIAlertController(title: "请选择主题分类", message: nil, preferredStyle: .actionSheet)
        for a in typeIds {
            sheet.addAction(UIAlertAction(title: a.value, style: .default) { ac in
                self.typeId = a.key
                self.subSeletedBtn.setTitle(a.value, for: .normal)
            })
        }
        self.present(sheet, animated: true, completion: nil)
    }
    
    @objc func postClick() {
        if !checkInput() { return }
        self.present(progress, animated: true, completion: nil)
        
        var params  = "topicsubmit=yes&subject=\(titleInput.text!)&message=\(contentInput.text!)"
        if let type = typeId {
            params = params + "&typeid="+type
        }
     
        HttpUtil.POST(url: Urls.newPostUrl(fid: self.fid!), params: params) { (ok, res) in
            //print(res)
            var success = false
            var message:String
            if ok {
                if res.contains("已经被系统拒绝") {
                    success = false
                    message = "由于未知原因发帖失败"
                }else {
                    success = true
                    message = "发帖成功!你要返回帖子列表吗？"
                }
            }else {
                success = false
                message = "网络不太通畅,请稍后重试"
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.progress.dismiss(animated: true, completion: nil)
                let alert = UIAlertController(title: success ? "发帖成功!" : "错误", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: success ? "取消" : "好", style: .cancel, handler: nil))
                if success {
                    alert.addAction(UIAlertAction(title: "返回", style: .default) { alert in
                        self?.navigationController?.popViewController(animated: true)
                    })
                }
                
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UINavigationController,let target = dest.topViewController as? ChooseForumViewController {
            target.delegate = self
            target.currentSelectFid = self.fid!
        }
    }
}

protocol ForumSelectDelegate {
    func selectFid(fid:Int,name:String)
}
