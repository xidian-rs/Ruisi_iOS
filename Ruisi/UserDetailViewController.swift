//
//  UserDetailViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

class UserDetailViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var uid:Int?
    var username:String?
    var datas = [KeyValueData<String,String>]()
    
    @IBOutlet weak var pointView: UILabel!
    @IBOutlet weak var levelProgressVIew: UIProgressView!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var levelView: UILabel!
    @IBOutlet weak var tabview: UITableView!
    @IBOutlet weak var loadingIndicate: UIActivityIndicatorView!
    
    private var loading = true
    private var currentPoint: Int = 0 //当前积分
    
    var isLoading:Bool {
        get {
            return loading
        }
        set {
            loading = newValue
            if !loading {
                loadingIndicate.stopAnimating()
            }else {
                loadingIndicate.startAnimating()
            }
            tabview.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabview.delegate = self
        tabview.dataSource = self
        
        if uid == nil {
            showBackAlert(message: "没有传入uid参数")
            return
        }
        
        avatarView.kf.setImage(with: Urls.getAvaterUrl(uid: uid!, size: 1), placeholder: #imageLiteral(resourceName: "placeholder"))
        
        self.title = username
        levelView.text = "--"
        loadData(uid: uid!)
        
        if App.uid != uid {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addClick))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "退出", style: .plain, target: self, action: #selector(exitClick))
        }
    }

    @objc func addClick() {
        let alert = UIAlertController(title: "添加好友", message: "你要添加\(username ?? "")为好友吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "添加", style: .default, handler: { (action) in
            self.doAddFriend()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func exitClick(){
        let alert = UIAlertController(title: "提示", message: "你要退出登陆吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "退出", style: .destructive, handler: { (action) in
            self.doExit()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func doAddFriend() {
        
    }
    
    func doExit() {
        // TODO
    }
    
    func loadData(uid: Int) {
        HttpUtil.GET(url: Urls.getUserDetailUrl(uid: uid), params: nil) { ok, res in
            if ok && uid == self.uid! { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    let nodes = doc.xpath("/html/body/div[1]/div[2]/ul/li")
                    for node in nodes {
                        var value = node.xpath("span").first?.text ?? ""
                        node.removeChild(node.xpath("span").first!)
                        let key = node.text ?? ""
                        
                        if key.contains("积分") {
                            self.currentPoint = Int(value) ?? 0
                            let level = RuisiUtil.getLevel(point: self.currentPoint)
                            DispatchQueue.main.async {
                                self.pointView.text = "积分: \(self.currentPoint) / \(RuisiUtil.getNextLevel(point: self.currentPoint))"
                                self.levelView.text = level
                                self.levelProgressVIew.progress = RuisiUtil.getLevelProgress(self.currentPoint)
                            }
                            self.datas.append(KeyValueData(key: "等级", value: level))
                        } else if key.contains("上传量") || key.contains("下载量") {
                            let a = Int64(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                            let gb = Double(a) / 1024 / 1024 / 1024.0
                            if gb > 500 {
                                let tb = gb / 1024.0
                                value = String(format: "%.2f TB", tb)
                            } else {
                                value = String(format: "%.2f GB", gb)
                            }
                        }
                        
                        self.datas.append(KeyValueData(key: key, value: value))
                    }
                }
            } else {
                self.datas.append(KeyValueData(key: "加载失败", value: ""))
            }
            
            DispatchQueue.main.async {
                //self.refreshView.attributedTitle = attrStr
                self.isLoading = false
            }
        }
    }
    
    private func showBackAlert(message: String) {
        let alert = UIAlertController(title: "无法查看用户信息", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "关闭", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isLoading {
            tableView.separatorStyle = .none
            return 0
        } else {
            tableView.separatorStyle = .singleLine
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let keyView = cell.viewWithTag(1) as! UILabel
        let valueView = cell.viewWithTag(2) as! UILabel
        
        keyView.text = datas[indexPath.row].key
        valueView.text = datas[indexPath.row].value
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
