//
//  ChatViewController.swift
//  Ruisi
//
//  Created by yang on 2017/11/30.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

class ChatViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var postingProgress: UIActivityIndicatorView!
    @IBOutlet weak var postBtn: UIButton!
    
    var uid: Int?
    var username: String?
    var isPresented = false
    var loadSuccess = false
    var datas = [ChatData]()
    
    var currentPage = 1
    var pageSum = Int.max
    var replyUrl: String?
    
    private var loading = false
    open var isLoading: Bool{
        get{
            return loading
        }
        set {
            loading = newValue
            if !loading {
                self.tableView.refreshControl?.endRefreshing()
            }else {
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        if uid == nil {
            showBackAlert(message: "没有传入uid参数")
            return
        }
        
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        tableView.delegate = self
        tableView.dataSource = self
        postingProgress.stopAnimating()
        
        if ((presentingViewController as? UserDetailViewController) != nil) {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(closeClick))
        }
        
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        
        self.title = username
        self.pageSum = 1
        
        // Initialize the refresh control.
        let refreshView = UIRefreshControl()
        Widgets.setRefreshControl(refreshView)
        refreshView.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        self.tableView.refreshControl = refreshView
        refreshView.beginRefreshing()
        loadData()
    }
    
    @IBAction func toggleBtnClick(_ sender: Any) {
        self.inputTextField.resignFirstResponder()
    }
    //down  up 
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            print(view.safeAreaInsets.bottom)
        }
    }
    
    @IBAction func submitClick(_ sender: UIButton) {
        if let text = inputTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            text.count > 0,let url = replyUrl {
            inputTextField.resignFirstResponder()
            postingProgress.startAnimating()
            postBtn.isEnabled = false
            HttpUtil.POST(url: url, params: ["touid":uid!,"message":text], callback: { [weak self] (ok, res) in
                //print(res)
                var success = false
                var reason: String?
                if ok {
                    if res.contains("操作成功") {
                        success = true
                        self?.datas.append(ChatData(uid: App.uid!, uname: App.username ?? "我", message: text, time: "刚刚"))
                    } else if res.contains("两次发送短消息太快") {
                        reason = "两次发送短消息太快，请稍候再发送"
                    }else {
                        reason = "我也不知道是什么原因发送失败"
                    }
                }else {
                    reason = "无法连接到睿思服务器,请检查网络连接"
                    //network error
                }
                
                DispatchQueue.main.async {
                    if success {
                        self?.tableView.beginUpdates()
                        self?.tableView.insertRows(at: [IndexPath.init(row: (self?.datas.count ?? 1) - 1, section: 0) ], with: .automatic)
                        self?.tableView.endUpdates()
                        self?.inputTextField.text = nil
                    }else {
                        let alert = UIAlertController(title: "错误", message: reason, preferredStyle: .alert)
                        let action = UIAlertAction(title: "好", style: .cancel, handler: nil)
                        alert.addAction(action)
                        self?.present(alert, animated: true)
                    }
                    
                    self?.postingProgress.stopAnimating()
                    self?.postBtn.isEnabled = true
                }
            })
        }
    }
    
    @objc func pullRefresh()  {
        loadData()
    }
    
    
    func loadData() {
        // 所持请求的数据正在加载中/未加载
        if isLoading {
            return
        }
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "正在加载")
        isLoading = true
        
        print("load data page:\(currentPage) sumPage:\(pageSum)")
        HttpUtil.GET(url: Urls.getChatDetailUrl(tuid:uid!), params: nil) { ok, res in
            //print(res)
            var subDatas:[ChatData] = []
            if ok,let doc = try? HTML(html: res, encoding: .utf8){ //返回的数据是我们要的
                
                // load replyUrl
                if let r =  doc.xpath("//*[@id=\"pmform\"]").first {
                    self.replyUrl = r["action"]
                    print("reply:\(self.replyUrl ?? "")")
                }
                
                //load subdata
                subDatas = self.parseData(doc: doc)
            }
            
            self.datas = subDatas
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
            
            var str: String
            if subDatas.count > 0 {
                let df =  DateFormatter()
                df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                str = "Last update: "+df.string(from: Date())
            }else{
                str = "加载失败"
            }
            
            let attrStr = NSAttributedString(string: str, attributes: [
                NSAttributedStringKey.foregroundColor:UIColor.gray])
            
            DispatchQueue.main.async {
                self.tableView.refreshControl?.attributedTitle = attrStr
                self.isLoading = false
                
                if self.currentPage < self.pageSum {
                    self.currentPage += 1
                }
            }
            
            print("finish http")
        }
    }
    
    func parseData(doc: HTMLDocument) -> [ChatData] {
        let msgs = doc.css(".msgbox .cl")
        print("msg count:\(msgs.count)")
        var subDatas = [ChatData]()
        for m in msgs {
            let uid:Int
            let username:String
            if m["class"]!.contains("friend_msg") {//左边 对方
                uid = self.uid!
                username = self.username ?? "对方"
            } else {//右边
                uid = App.uid!
                username = App.username ?? "我"
            }
            
            let content = m.css(".dialog_t").first?.text ?? "" //TODO innerHtml
            let time = m.css(".date").first?.text ?? ""
            
            subDatas.append(ChatData(uid: uid, uname: username, message: content, time: time))
        }
        
        print("data count:\(subDatas.count)")
        if subDatas.count == 0 {
            loadSuccess = false
            pageSum = currentPage
        }else {
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
        }else { //me
            cell = tableView.dequeueReusableCell(withIdentifier: "rightCell", for: indexPath)
        }
        
        let avatar = cell.viewWithTag(1) as! UIImageView
        let contentLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel = cell.viewWithTag(3) as! UILabel
        
        avatar.kf.setImage(with: Urls.getAvaterUrl(uid: data.uid), placeholder: #imageLiteral(resourceName: "placeholder"))
        timeLabel.text = data.time
        contentLabel.text = data.message
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            let label = UILabel(frame:CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = "加载中..."
            label.textColor = UIColor.black
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20)
            label.textColor = UIColor.lightGray
            label.sizeToFit()
            
            tableView.backgroundView = label;
            tableView.separatorStyle = .none;
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return 1
        }
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
