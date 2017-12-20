//
//  MesageViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 首页 - 消息
class MessageViewController: BaseTableViewController<MessageData> {
    
    private var lastLoginState = false
    
    override func viewDidLoad() {
        
        self.autoRowHeight = true
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        lastLoginState = App.isLogin
        if lastLoginState {
            self.refreshControl = refreshView
            loadData(position)
        } else {
            self.emptyPlaceholderText = "需要登陆才能查看"
            self.refreshControl = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastLoginState != App.isLogin {
            lastLoginState = App.isLogin
            if lastLoginState { //未登陆转为登陆
                self.refreshControl = refreshView
                self.tableView.reloadData()
                loadData(position)
            } else { //登陆转为未登陆
                datas.removeAll()
                tableView.reloadData()
                self.refreshControl = nil
            }
        }
    }
    
    // 切换回复0 和 PM1 AT2
    @IBAction func messageTypeChange(_ sender: UISegmentedControl) {
        position = sender.selectedSegmentIndex
        self.isLoading = false
        if App.isLogin {
            self.emptyPlaceholderText = "加载中..."
            self.datas = []
            self.tableView.reloadData()
            pullRefresh()
        } else {
            self.datas.removeAll()
            self.emptyPlaceholderText = "需要登陆才能查看"
            self.tableView.reloadData()
        }
    }
    
    var isReplyLoading = false
    var isPmLoading = false
    var isAtLoading = false
    
    override var isLoading: Bool {
        get {
            if position == 0 {
                return isReplyLoading
            } else if position == 1 {
                return isPmLoading
            } else {
                return isAtLoading
            }
        }
        
        set {
            if position == 0 {
                isReplyLoading = newValue
            } else if position == 1 {
                isPmLoading = newValue
            } else {
                isAtLoading = newValue
            }
            
            super.isLoading = newValue
        }
    }
    
    override func getUrl(page: Int) -> String {
        if position == 0 {
            return Urls.messageReply + "&page=\(currentPage)"
        } else if position == 1 {
            return Urls.messagePm + "&page=\(currentPage)"
        } else {
            return Urls.messageAt + "&page=\(currentPage)"
        }
    }
    
    override func parseData(pos: Int, doc: HTMLDocument) -> [MessageData] {
        var subDatas = [MessageData]()
        let nodes: XPathObject
        if pos == 0 || pos == 2 { // reply at
            currentPage = Int(doc.xpath("/html/body/div[8]/div[3]/div[1]/div/div[2]/div/strong").first?.text ?? "") ?? currentPage
            totalPage = Utils.getNum(from: (doc.xpath("/html/body/div[8]/div[3]/div[1]/div/div[2]/div/label/span").first?.text) ?? "") ?? currentPage
            nodes = doc.xpath("//*[@id=\"ct\"]/div[1]/div/div[1]/div/dl") //.css(".nts .cl")
        } else {// pm
            currentPage = Int(doc.xpath("/html/body/div[2]/strong").first?.text ?? "") ?? currentPage
            totalPage = Utils.getNum(from: (doc.xpath("/html/body/div[2]/label/span").first?.text) ?? "") ?? currentPage
            print("======\(currentPage)   \(totalPage)")
            nodes = doc.xpath("/html/body/div[1]/ul/li") //.css(".pmbox ul li")
        }
        
        var type: MessageType
        var title: String
        var tid: Int
        var author: String //处理过后的
        var uid: Int? // 系统无uid
        var time: String
        var content: String
        var isRead: Bool
        
        for ele in nodes {
            isRead = true
            if pos == 0 {//reply
                type = .Reply
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
                
                isRead = (ele.css(".ntc_body").first?["style"]?.contains("font-weight:bold") ?? true) ? false : true
            } else if pos == 1 { //pm
                type = .Pm
                if let _ = ele.css(".num").first {
                    isRead = false
                } else {
                    isRead = true
                }
                title = ""
                author = ele.css(".cl").first?.css(".name").first?.text ?? ""
                time = ele.css(".cl.grey .time").first?.text ?? "未知时间"
                content = ele.css(".cl.grey span")[1].text ?? ""
                uid = Utils.getNum(from: ele.css("img").first?["src"] ?? "0")
                //在这里tid = tuid
                tid = Utils.getNum(from: ele.css("a").first?["href"] ?? "0") ?? 0
            } else { //at
                type = .At
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
                isRead = (ele.css(".ntc_body").first?["style"]?.contains("font-weight:bold") ?? true) ? false : true
            }
            
            
            let d = MessageData(type: type, title: title, tid: tid, uid: uid, author: author,
                                time: time, content: content.trimmingCharacters(in: .whitespacesAndNewlines), isRead: isRead)
            subDatas.append(d)
        }
        return subDatas
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let data = datas[indexPath.row]
        let avaterView = cell.viewWithTag(1) as! UIImageView
        let authorLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel = cell.viewWithTag(3) as! UILabel
        let messageContent = cell.viewWithTag(4) as! UILabel
        let isReadLabel = cell.viewWithTag(5) as! UILabel
        
        avaterView.layer.cornerRadius = avaterView.frame.width / 2
        if let uid = data.uid {
            avaterView.kf.setImage(with: Urls.getAvaterUrl(uid: uid), placeholder: #imageLiteral(resourceName:"placeholder"))
            avaterView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick(_:))))
        } else {
            avaterView.image = #imageLiteral(resourceName:"systempm")
        }
        
        timeLabel.text = data.time
        authorLabel.text = data.author//[解析过后的]
        messageContent.text = data.content
        isReadLabel.isHidden = data.isRead
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        if !datas[indexPath.row].isRead {
            datas[indexPath.row].isRead = true
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        if position == 1 { //pm
            self.performSegue(withIdentifier: "chatListToChat", sender: indexPath)
        } else {
            self.performSegue(withIdentifier: "messageListToPostSegue", sender: indexPath)
        }
    }
    
    @objc func loginClick() {
        //login
        let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
        self.present(dest!, animated: true, completion: nil)
    }
    
    @objc func avatarClick(_ sender: UITapGestureRecognizer) {
        if let index = tableView.indexPath(for: sender.view?.superview?.superview as! UITableViewCell) {
            if datas[index.row].uid != nil {
                self.performSegue(withIdentifier: "messageToUserDetail", sender: index)
            }
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let index = sender as? IndexPath {
            dest.title = datas[index.row].title
            dest.tid = datas[index.row].tid
        } else if let dest = segue.destination as? UserDetailViewController,
            let index = sender as? IndexPath {
            if let uid = datas[index.row].uid {
                dest.uid = uid
                dest.username = nil
            }
        } else if let dest = segue.destination as? ChatViewController,
            let index = sender as? IndexPath {
            if let uid = datas[index.row].uid {
                dest.uid = uid
                dest.username = datas[index.row].author
                    .replacingOccurrences(of: " 对我说:", with: "")
                    .replacingOccurrences(of: "我对 ", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "说:"))
            }
        }
    }
}
