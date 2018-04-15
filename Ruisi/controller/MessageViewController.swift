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
// TODO 支持消息小圆点
class MessageViewController: BaseTableViewController<MessageData>, ScrollTopable {
    
    private var lastLoginState = false
    private var emptyPlaceholderText: String?
    private var initContentOffset: CGFloat = 0.0
    
    override func viewDidLoad() {
        self.autoRowHeight = false
        lastLoginState = App.isLogin
        showRefreshControl = lastLoginState
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if !lastLoginState { // 非登陆状态
            self.emptyPlaceholderText = "需要登陆才能查看"
        }
        initContentOffset = self.tableView.contentOffset.y
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastLoginState != App.isLogin {
            lastLoginState = App.isLogin
            showRefreshControl = lastLoginState
            if lastLoginState { //未登陆转为登陆
                rsRefreshControl?.beginRefreshing()
                loadData(position)
            } else { //登陆转为未登陆
                datas.removeAll()
                tableView.reloadData()
            }
        }
    }
    
    func scrollTop() {
        if self.tableView?.contentOffset.y ?? initContentOffset > initContentOffset {
            self.tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        } else if !isLoading {
            self.datas = []
            self.tableView.reloadData()
            self.rsRefreshControl?.beginRefreshing()
            reloadData()
        }
    }
    
    // FIXME 好像没调用 时机不对
    override func loadData(_ pos: Int) {
        if !App.isLogin {
            return
        }
        super.loadData(pos)
        updateUnreads()
    }
    
    // 切换回复0 和 PM1 AT2
    @IBAction func messageTypeChange(_ sender: UISegmentedControl) {
        position = sender.selectedSegmentIndex
        self.isLoading = false
        if App.isLogin {
            self.emptyPlaceholderText = nil
            self.datas = []
            self.tableView.reloadData()
            self.rsRefreshControl?.beginRefreshing()
            reloadData()
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
    
    // 设置badge
    func updateUnreads()  {
        let unreadCount =  self.datas.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
        if let tabBarVc = self.tabBarController {
            if unreadCount > 0 {
                tabBarVc.tabBar.selectedItem?.badgeValue = unreadCount < 9 ? String(unreadCount) : "9+"
            } else {
                tabBarVc.tabBar.selectedItem?.badgeValue = nil
            }
        }
    }
    
    override func parseData(pos: Int, doc: HTMLDocument) -> [MessageData] {
        var subDatas = [MessageData]()
        let nodes: XPathObject
        if pos == 0 || pos == 2 { // reply at
            currentPage = Int(doc.xpath("//*[@id=\"ct\"]/div[1]/div/div[2]/div/strong").first?.text ?? "") ?? currentPage
            totalPage = Utils.getNum(from: (doc.xpath("//*[@id=\"ct\"]/div[1]/div/div[2]/div/label/span").first?.text) ?? "") ?? currentPage
            nodes = doc.xpath("//*[@id=\"ct\"]/div[1]/div/div[1]/div/dl") //.css(".nts .cl")
        } else {// pm
            currentPage = 1
            totalPage = 1 //TODO 拿不到
            nodes = doc.xpath("/html/body/div/ul/li") //.css(".pmbox ul li")
        }
        
        var type: MessageType
        var title: String
        var tid: Int
        var author: String //处理过后的
        var uid: Int? // 系统无uid
        var time: String
        var content: String
        var isRead: Bool
        var pid: Int?
        
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
                    pid = Utils.getNum(prefix: "pid=", from: aa["href"]!)
                } else { //系统消息
                    author = "系统消息"
                    let a = ele.css(".ntc_body a").first
                    title = a?.text ?? "未知主题"
                    content = (ele.css(".ntc_body").first?.text)!
                    tid = Utils.getNum(from: a?["href"] ?? "0") ?? 0
                    pid = nil
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
                pid = nil
            } else { //at
                type = .At
                time = ele.css(".xg1.xw0").first?.text ?? "未知时间"
                
                if let t = ele.xpath("dd[2]/a[2]").first {
                    tid = Utils.getNum(from: t["href"]!) ?? 0
                    pid = Utils.getNum(prefix: "pid=", from: t["href"]!)
                } else {
                    tid = 0
                    pid = nil
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
            
            let d = MessageData(type: type, title: title, tid: tid,pid: pid, uid: uid, author: author,
                                time: time, content: content.trimmingCharacters(in: .whitespacesAndNewlines), isRead: isRead)
            d.rowHeight = caculateRowheight(width: self.tableViewWidth, content: d.content)
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        _ = super.numberOfSections(in: tableView)
        if datas.count == 0 {//no data avaliable
            if let title = emptyPlaceholderText {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
                label.text = title
                label.textColor = UIColor.darkGray
                label.numberOfLines = 0
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 20)
                label.textColor = UIColor.lightGray
                label.sizeToFit()
                
                tableView.backgroundView = label
                tableView.separatorStyle = .none
            }
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = datas[indexPath.row]
        return d.rowHeight
    }
    
    // 计算行高 content 最多4行最高72
    private func caculateRowheight(width: CGFloat, content: String) -> CGFloat {
        let contentHeight = min(content.height(for: width - 30 - 36 - 8, font: UIFont.systemFont(ofSize: 15)), 72)
        // 上间距(12) + 标题(19.5) + 间距(5) + 正文(计算) + 下间距(10)
        // 12 是arrawLabel的内边距
        return 12 + 19.5 + 5 + contentHeight + 12 + 10
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        if !datas[indexPath.row].isRead {
            datas[indexPath.row].isRead = true
            tableView.reloadRows(at: [indexPath], with: .automatic)
            updateUnreads()
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
            dest.pid = datas[index.row].pid
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
