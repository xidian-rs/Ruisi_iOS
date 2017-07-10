//
//  MesageViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

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
    
    func pullRefresh() {
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
            var subDatas = [ArticleListDataSimple]()
            if ok && pos == self.position { //返回的数据是我们要的
                if let doc = HTML(html: res, encoding: .utf8) {
                    for li in doc.css(".threadlist ul li") {
                        let a = li.css("a").first
                        
                        var tid: Int?
                        if let u = a?["href"] {
                            tid = Utils.getNum(from: u)
                        } else {
                            //没有tid和咸鱼有什么区别
                            continue
                        }
                        
                        var replysStr: String?
                        var authorStr: String?
                        let replys = li.css("span.num").first
                        let author = li.css(".by").first
                        if let r =  replys {
                            replysStr = r.text
                            a?.removeChild(r)
                        }
                        if let au =  author {
                            authorStr = au.text
                            a?.removeChild(au)
                        }
                        let img = (li.css("img").first)?["src"]
                        var haveImg = false
                        if let i =  img {
                            haveImg = i.contains("icon_tu.png")
                        }
                        
                        
                        let title = a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n "))
                        
                        let color =  Utils.getHtmlColor(from: a?["style"])
                        let d = ArticleListDataSimple(title: title ?? "未获取到标题", tid: tid!, author: authorStr ?? "未知作者",replys: replysStr ?? "0", read: false, haveImage: haveImg, titleColor: color)
                        subDatas.append(d)
                    }
                    
                    print("finish load data pos:\(pos) count:\(subDatas.count)")
                }
            }
            
            //load data ok
            if pos == self.position {
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
                
                var str: String
                if subDatas.count > 0 {
                    let df =  DateFormatter()
                    df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                    str = "Last update: "+df.string(from: Date())
                }else{
                    str = "加载失败"
                }
                
                let attrStr = NSAttributedString(string: str, attributes: [
                    NSForegroundColorAttributeName:UIColor.gray])
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 1 * NSEC_PER_SEC)){
                    self.refreshView.attributedTitle = attrStr
                    self.isLoading = false
                }
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
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let authorLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel  = cell.viewWithTag(3) as! UILabel
        let messageContent = cell.viewWithTag(4) as! UILabel
        
        imageView.layer.cornerRadius = imageView.frame.width / 2
        timeLabel.text = data.time
        authorLabel.text = data.author//[解析过后的]
        
        switch data.type {
        case .At:
            messageContent.text = "在主题[\(data.title)]\n\(data.content)"
        case .Pm:
            messageContent.text = data.content
        default: //reply
            
            messageContent.text = data.title
        }
        
        messageContent.text = data.title
        return cell
    }

    func loginClick()  {
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
        
    }
  

}
