//
//  ChatViewController.swift
//  Ruisi
//
//  Created by yang on 2017/11/30.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 聊天
// TODO 手动行高
class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var replyView: SimpleReplyView!
    private lazy var rsRefreshControl =  RSRefreshControl()
    
    var uid: Int?
    var username: String?
    var isPresented = false
    var loadSuccess = false
    var datas = [ChatData]()
    
    var currentPage = 1
    var pageSum = Int.max
    var replyUrl: String?
    
    private var loading = false
    
    override func viewDidLoad() {
        if uid == nil {
            showBackAlert(message: "没有传入uid参数")
            return
        }
        
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        tableView.separatorStyle = .none;
        tableView.delegate = self
        tableView.dataSource = self
        
        replyView.isSending = false
        replyView.shouldHandleKeyBoard = false
        replyView.placeholder = "发送私信"
        self.replyView.enableTail = false
        self.replyView.minTextLen = 8
        
        replyView.onSubmitClick { [weak self] text in
            self?.doSubmit(text: text)
        }
        
        if ((presentingViewController as? UserDetailViewController) != nil) {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(closeClick))
        }
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.title = username
        self.pageSum = 1
        
        tableView.addSubview(rsRefreshControl)
        rsRefreshControl.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        rsRefreshControl.beginRefreshing()
        loadData()
    }
    
    private func doSubmit(text: String) {
        replyView.isSending = true
        
        let url = replyUrl ?? Urls.postChatUrl(tuid: uid!)
        HttpUtil.POST(url: url, params: ["touid": uid!, "message": text], callback: { [weak self] (ok, res) in
            //print(res)
            var success = false
            var reason: String?
            if ok {
                if res.contains("操作成功") {
                    success = true
                    self?.datas.append(ChatData(uid: App.uid!, uname: App.username ?? "我", message: text, time: "刚刚"))
                } else if res.contains("两次发送短消息太快") {
                    reason = "两次发送短消息太快，请稍候再发送"
                } else {
                    reason = "我也不知道是什么原因发送失败"
                }
            } else {
                reason = "无法连接到睿思服务器,请检查网络连接"
                //network error
            }
            
            DispatchQueue.main.async {
                if success {
                    self?.tableView.beginUpdates()
                    self?.tableView.insertRows(at: [IndexPath.init(row: (self?.datas.count ?? 1) - 1, section: 0)], with: .automatic)
                    self?.tableView.endUpdates()
                    self?.replyView.clearText(hide: false)
                } else {
                    let alert = UIAlertController(title: "错误", message: reason, preferredStyle: .alert)
                    let action = UIAlertAction(title: "好", style: .cancel, handler: nil)
                    alert.addAction(action)
                    self?.present(alert, animated: true)
                }
                
                self?.replyView.isSending = false
            }
        })
    }
    
    
    @objc func reloadData() {
        currentPage = 1
        pageSum = Int.max
        
        loadData()
    }
    
    func loadData() {
        // 所持请求的数据正在加载中/未加载
        if loading {
            return
        }
        loading = true
        print("load data page:\(currentPage) sumPage:\(pageSum)")
        HttpUtil.GET(url: Urls.getChatDetailUrl(tuid: uid!), params: nil) { ok, res in
            var subDatas: [ChatData] = []
            if ok, let doc = try? HTML(html: res, encoding: .utf8) { //返回的数据是我们要的
                
                // load replyUrl
                if let r = doc.xpath("//*[@id=\"pmform\"]").first {
                    self.replyUrl = r["action"]
                }
                
                //load subdata
                subDatas = self.parseData(doc: doc)
            }
            
            DispatchQueue.main.async {
                self.datas = subDatas
                self.tableView.reloadData()

                if self.currentPage < self.pageSum {
                    self.currentPage += 1
                }
                
                self.rsRefreshControl.endRefreshing(message: ok ? "加载成功": "加载失败")
                self.loading = false
            }
        }
    }
    
    func parseData(doc: HTMLDocument) -> [ChatData] {
        let msgs = doc.css(".msgbox .cl")
        var subDatas = [ChatData]()
        for m in msgs {
            let uid: Int
            let username: String
            if m["class"]!.contains("friend_msg") {//左边 对方
                uid = self.uid!
                username = self.username ?? "对方"
            } else {//右边
                uid = App.uid!
                username = App.username ?? "我"
            }
            
            let content = m.css(".dialog_t").first?.innerHTML ?? ""
            let time = m.css(".date").first?.text ?? ""
            
            subDatas.append(ChatData(uid: uid, uname: username, message: content, time: time))
        }
        
        if subDatas.count == 0 {
            loadSuccess = false
            pageSum = currentPage
        } else {
            loadSuccess = true
        }
        
        if subDatas.count == 0 && currentPage == 1 { //无消息
            subDatas.append(ChatData(uid: self.uid!, uname: self.username ?? "", message: "给我发消息吧...", time: "刚刚"))
        }
        
        return subDatas
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = datas[indexPath.row]
        
        let cell: UITableViewCell
        if data.uid == uid { //him
            cell = tableView.dequeueReusableCell(withIdentifier: "leftCell", for: indexPath)
        } else { //me
            cell = tableView.dequeueReusableCell(withIdentifier: "rightCell", for: indexPath)
        }
        
        let avatar = cell.viewWithTag(1) as! UIImageView
        let contentLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel = cell.viewWithTag(3) as! UILabel
    
        avatar.kf.setImage(with: Urls.getAvaterUrl(uid: data.uid), placeholder: #imageLiteral(resourceName:"placeholder"))
        timeLabel.text = data.time
        contentLabel.attributedText = AttributeConverter(font: contentLabel.font, textColor: contentLabel.textColor).convert(src: data.message)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    private func showBackAlert(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "关闭", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    @objc func closeClick() {
        self.dismiss(animated: true, completion: nil)
    }
}
