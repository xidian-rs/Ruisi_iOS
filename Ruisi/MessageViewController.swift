//
//  MesageViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 我的消息页面
class MessageViewController: UITableViewController {
    
    var datas = [MessageData]()
    var position = 0 //为了hotnew而准备的
    var currentPage = 1
    
    var isReplyLoading = false
    var isPmLoading = false
    var isAtLoading = false
    var refreshView: UIRefreshControl!
    var lastLoginState = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 120
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        // Initialize the refresh control.
        refreshView = UIRefreshControl()
        Widgets.setRefreshControl(refreshView)
        refreshView.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        lastLoginState = App.isLogin
        if lastLoginState {
            self.refreshControl = refreshView
            loadData(pos: position)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastLoginState != App.isLogin {
            lastLoginState = App.isLogin
            datas.removeAll()
            tableView.reloadData()
            
            if lastLoginState { //未登陆转为登陆
                self.refreshControl = refreshView
                loadData(pos: position)
            } else { //登陆转为未登陆
                self.refreshControl = nil
            }
        }
    }
    
    // 切换回复0 和 PM1 AT2
    @IBAction func messageTypeChange(_ sender: UISegmentedControl) {
        position = sender.selectedSegmentIndex
        currentPage = 1
        
        if App.isLogin {
            loadData(pos: position)
        }
    }
    
    var isLoading: Bool {
        get {
            if position == 0 {
                return isReplyLoading
            }else if position == 1{
                return isPmLoading
            } else {
                return isAtLoading
            }
        }
        
        set {
            if position == 0 {
                isReplyLoading = newValue
            }else if position == 1{
                isPmLoading = newValue
            }else {
                isAtLoading = newValue
            }
            
            if !newValue {
                refreshView.endRefreshing()
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading()
                }
            }else {
                //refreshView.beginRefreshing()
                if currentPage > 1 { //上拉刷新
                    if let f = (tableView.tableFooterView as? LoadMoreView) {
                        f.startLoading()
                    }
                }
            }
        }
    }
    
    
    var url: String {
        if position == 0 {
            return Urls.messageReply + "&page=\(currentPage)"
        }else if position == 1{
            return Urls.messagePm + "&page=\(currentPage)"
        } else {
            return Urls.messageAt + "&page=\(currentPage)"
        }
    }
    
    @objc func pullRefresh() {
        print("下拉刷新'")
        currentPage = 1
        loadData(pos: position)
    }
    
    // todo
    func loadData(pos: Int) {
        // 所持请求的数据正在加载中/未加载/未登陆
        if isLoading || !App.isLogin {
            return
        }
        refreshView.attributedTitle = NSAttributedString(string: "正在加载")
        isLoading = true
        
        print("load data page \(currentPage)")
        HttpUtil.GET(url: url, params: nil) { ok, res in
            var subDatas = [MessageData]()
            var infoText: String?
            if ok && pos == self.position { //返回的数据是我们要的
                let nodes: XPathObject
                if pos == 0 || pos == 2 { // reply at
                    nodes = try! HTML(html: res, encoding: .utf8).xpath("//*[@id=\"ct\"]/div[1]/div/div[1]/div/dl") //.css(".nts .cl")
                } else {// pm
                    nodes = try! HTML(html: res, encoding: .utf8).xpath("/html/body/div[1]/ul/li") //.css(".pmbox ul li")
                }
                var type: MessageType
                var title: String
                var tid: Int
                var author: String //处理过后的
                var uid: Int? // 系统无uid
                var time: String
                var content: String
                var isRead: Bool
                
                let messageId = Settings.getMessageId(type: pos)
                for ele in nodes {
                    if pos == 0 {//reply
                        type = .Reply
                        let id = Utils.getNum(from: ele["notice"] ?? "0") ?? 0
                        isRead =  (id <= messageId)
                        time = ele.css(".xg1.xw0").first?.text ?? "未知时间"
                        let a = ele.css(".ntc_body a[href^=forum.php?mod=redirect]").first
                        if let aa = a {
                            let authorA = ele.css(".ntc_body a[href^=home.php?mod=space]").first!
                            uid = Utils.getNum(from: authorA["href"] ?? "0")
                            author = "\(authorA.text!) 回复了我"
                            title = aa.text ?? "未知主题"
                            content = title
                            tid = Utils.getNum(from: aa["href"]!) ?? 0
                        } else { //系统消息
                            author = "系统消息"
                            let a = ele.css(".ntc_body a").first
                            title = a?.text ?? "未知主题"
                            content = (ele.css(".ntc_body").first?.text)!
                            tid = Utils.getNum(from: a?["href"] ?? "0") ?? 0
                            uid = nil
                        }
                    }else if pos == 1 { //pm
                        type = .Pm
                        if let _ = ele.css(".num").first {
                            isRead = false
                        }else {
                            isRead = true
                        }
                        title = ""
                        author = ele.css(".cl").first?.css(".name").first?.text ?? ""
                        time = ele.css(".cl.grey .time").first?.text ?? "未知时间"
                        content = ele.css(".cl.grey span")[1].text ?? ""
                        uid = Utils.getNum(from: ele.css("img").first?["src"] ?? "0")
                        //在这里tid = tuid
                        tid = Utils.getNum(from: ele.css("a").first?["href"] ?? "0") ?? 0
                    }else { //at
                        type = .At
                        let id = Utils.getNum(from: ele["notice"] ?? "0") ?? 0
                        isRead =  (id <= messageId)
                        time = ele.css(".xg1.xw0").first?.text ?? "未知时间"
                    
                        if let t = ele.xpath("dd[2]/a[2]").first {
                            tid = Utils.getNum(from: t["href"]!) ?? 0
                        } else {
                            tid = 0
                        }
        
                        let authorA = ele.css(".ntc_body a[href^=home.php?mod=space]").first
                        if let aa = authorA {
                            author = "\(aa.text!) 提到了我"
                            uid = Utils.getNum(from: aa["href"]!)
                        } else {
                            author = "未知"
                            uid = nil
                        }
                        
                        title = ele.css(".ntc_body a[href^=forum.php?mod=redirect]").first?.text ?? "未知主题"
                        content = "在主题[\(title)]\n\(ele.css(".ntc_body .quote").first?.text ?? "未获取到内容")"
                    }
                
                    
                    let d = MessageData(type: type, title: title, tid: tid, uid: uid, author: author,
                                        time: time, content: content.trimmingCharacters(in: .whitespacesAndNewlines),isRead: isRead)
                    subDatas.append(d)
                }
            
                print("finish load data pos:\(pos) count:\(subDatas.count)")
                // 第一次换页清空
                if self.currentPage == 1 {
                    self.datas = subDatas
                    DispatchQueue.main.async{
                        self.tableView.reloadData()
                    }
                } else {
                    let count = self.datas.count
                    self.datas.append(contentsOf: subDatas)
                    DispatchQueue.main.async{
                        self.tableView.beginUpdates()
                        var indexs = [IndexPath]()
                        for i in 0 ..< subDatas.count {
                            indexs.append(IndexPath(row: count + i, section: 0))
                        }
                        self.tableView.insertRows(at: indexs, with: .automatic)
                        self.tableView.endUpdates()
                    }
                }
                
                self.currentPage += 1
                if subDatas.count > 0 {
                    let df =  DateFormatter()
                    df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                    infoText = "Last update: "+df.string(from: Date())
                }else{
                    infoText = "暂无更多"
                }
            } else {
                if !ok {
                    infoText = "网络错误"
                }
                print("not ok or pos not same")
            }
            
            
            DispatchQueue.main.async {
                if let text = infoText {
                    let attrStr = NSAttributedString(string: text, attributes: [
                        NSAttributedStringKey.foregroundColor:UIColor.gray])
                    self.refreshView.attributedTitle = attrStr
                }
                self.isLoading = false
            }
            
            print("finish http")
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            if App.isLogin {
                let label = UILabel(frame:CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
                label.text = "加载中..."
                label.textColor = UIColor.black
                label.numberOfLines = 0
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 20)
                label.textColor = UIColor.lightGray
                label.sizeToFit()
                tableView.backgroundView = label
            }else {
                let btn = UIButton(frame:CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
                btn.setTitleColor(UIColor.lightGray, for: .normal)
                btn.setTitle("需要登陆,点我登陆", for: .normal)
                btn.titleLabel?.textAlignment = .center
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                let rec = UITapGestureRecognizer(target: self, action: #selector(loginClick))
                btn.addGestureRecognizer(rec)
                tableView.backgroundView = btn
            }
            
            tableView.separatorStyle = .none
            tableView.tableFooterView?.isHidden = true
            
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.tableFooterView?.isHidden = false
            tableView.separatorStyle = .singleLine
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let data  = datas[indexPath.row]
        
        let avaterView = cell.viewWithTag(1) as! UIImageView
        let authorLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel  = cell.viewWithTag(3) as! UILabel
        let messageContent = cell.viewWithTag(4) as! UILabel
        
        avaterView.layer.cornerRadius = avaterView.frame.width / 2
        avaterView.kf.setImage(with: Urls.getAvaterUrl(uid: data.uid ?? 0), placeholder: #imageLiteral(resourceName: "placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        timeLabel.text = data.time
        authorLabel.text = data.author//[解析过后的]
        messageContent.text = data.content
        return cell
    }
    
    @objc func loginClick()  {
        //login
        let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
        self.present(dest!, animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !datas[indexPath.row].isRead
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
                let index = tableView.indexPath(for: cell)!
                dest.title = datas[index.row].title
                dest.tid = datas[index.row].tid
            }
    }
    
    
}
