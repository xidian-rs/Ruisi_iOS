//
//  PostViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/20.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher
import Kanna

// 帖子详情页
class PostViewController: UIViewController,UITextViewDelegate,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var replyBoxView: ReplyBoxView!
    
    var datas = [PostData]()
    var tid: Int? // 由前一个页面传过来的值
    var saveToHistory = false //是否保存到历史记录
    var contentTitle: String?
    
    var currentPage: Int = 1
    var pageSum: Int = 1
    var refreshView: UIRefreshControl!
    
    private var loading = false
    open var isLoading: Bool{
        get{
            return loading
        }
        set {
            loading = newValue
            if !loading {
                refreshView.endRefreshing()
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading(haveMore: currentPage < pageSum)
                }
            }else {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.startLoading()
                }
            }
        }
    }
    
    func getUrl(page: Int) -> String {
        if self.currentPage > self.pageSum {
            self.currentPage = self.pageSum
            return Urls.getPostUrl(tid: tid!) + "&page=\(pageSum)"
        } else {
            return Urls.getPostUrl(tid: tid!) + "&page=\(page)"
        }
    }
    
    // close
    // self.navigationController?.popViewController(animated: true)
    override func viewDidLoad() {
        if tid == nil {
            showBackAlert(message: "没有传入tid参数")
            return
        }
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        
        // 隐藏回复框
        replyBoxView.hideInputBox()
        replyBoxView.onSubmit { (content,isLz,pos) in
            if let message = content,message.trimmingCharacters(in: CharacterSet.whitespaces).count > 0 {
                print("message is:||\(message)||len:\(message.count)")
                self.doReply(islz: isLz, message: message, pos: pos)
            }
        }
        
        //navigationController?.hidesBarsOnSwipe = true
        // TODO it will change all the nav
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        // Initialize the refresh control.
        refreshView = UIRefreshControl()
        Widgets.setRefreshControl(refreshView)
        refreshView.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        tableView.refreshControl = refreshView
        refreshView.beginRefreshing()
        
        loadData()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            Settings.safeAeraBottomInset =  Float(view.safeAreaInsets.bottom)
        }
    }
    
    
    @objc func pullRefresh(){
        print("下拉刷新'")
        currentPage = 1
        pageSum = Int.max
        loadData()
    }
    
    //刷新数据
    @objc func refreshData() {
        print("refresh click")
        self.currentPage = 1
        self.loadData()
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
            tableView.tableFooterView?.isHidden = true
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.tableFooterView?.isHidden = false
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
    
    @IBAction func backToTopClick(_ sender: Any) {
        tableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    // load more
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = datas.count - 1
        if !isLoading && indexPath.row == lastElement {
            print("load more")
            loadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data: PostData
        let cell: UITableViewCell
        if indexPath.row == 0 {
            data = datas[0]
            cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath)
            let title = cell.viewWithTag(6) as! UILabel
            title.text = contentTitle ?? self.title
        } else {
            data = datas[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath)
            let index = cell.viewWithTag(6) as! UILabel
            index.text = data.index
            let replyBtn =  cell.viewWithTag(7) as? UIButton
            if data.replyUrl != nil {
                replyBtn?.isHidden = false
                replyBtn?.addTarget(self, action: #selector(replyCzClick(_:)), for: .touchUpInside)
            }else {
                replyBtn?.isHidden = true
            }
        }
        
        let img = cell.viewWithTag(1) as! UIImageView
        let author = cell.viewWithTag(2) as! UILabel
        let lz = cell.viewWithTag(3) as! UILabel
        let time = cell.viewWithTag(4) as! UILabel
        let content = cell.viewWithTag(5) as! UITextView
        
        lz.isHidden = datas[0].author != data.author
        
        author.text = data.author
        time.text = data.time
        img.kf.setImage(with:  Urls.getAvaterUrl(uid: data.uid))
        img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick(_:))))
        content.delegate = self
        content.isEditable = false
        content.isScrollEnabled  = false
        content.attributedText = AtrributeConveter().convert(src: data.content)
        return cell
    }
    
    
    func loadData() {
        // 所持请求的数据正在加载中/未加载
        if isLoading {
            return
        }
        
        refreshView.attributedTitle = NSAttributedString(string: "正在加载")
        isLoading = true
        
        print("load data page:\(currentPage) sumPage:\(pageSum)")
        HttpUtil.GET(url: getUrl(page: currentPage), params: nil) { ok, res in
            //print(res)
            var subDatas:[PostData] = []
            if ok { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    // load fromHash
                    let exitNode = doc.xpath("/html/body/div[@class=\"footer\"]/div/a[2]").first
                    if let hash =  Utils.getFormHash(from: exitNode?["href"]) {
                        App.formHash = hash
                    }
                    
                    //load subdata
                    subDatas = self.parseData(doc: doc)
                }
            }
            print("currentPage:\(self.currentPage) subCount:\(subDatas.count) count:\(self.datas.count)")
            if subDatas.count == 0 { //没有加载到数据
                self.pageSum = self.currentPage
            } else if self.currentPage == 1 && self.datas.count == 0 { // 第一次换页清空
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
                self.refreshView.attributedTitle = attrStr
                self.isLoading = false
                
                if self.currentPage < self.pageSum {
                    self.currentPage += 1
                }
            }
            
            print("finish http")
        }
    }
    
    // 子类重写此方法支持解析自己的数据
    func parseData(doc: HTMLDocument) -> [PostData]{
        var subDatas:[PostData] = []
        if self.contentTitle == nil, let t = doc.title {
            self.contentTitle = String(t[..<t.index(of: " - ")!])
        }
        
        let comments = doc.xpath("/html/body/div[1]/div[@class=\"plc cl\"]")
        if comments.count > 0 {
            //获得回复楼主的url
            var replyUrl: String?
            if self.datas.count == 0 {
                replyUrl =  doc.xpath("//*[@id=\"fastpostform\"]").first?["action"]
            }
            
            //获取总页数 和当前页数
            if let pg =  doc.css(".pg").first {
                // var page = Utils.getNum(from: pg.css("strong").first?.text ?? "1")
                let sum = Utils.getNum(from: pg.css("span").first?["title"] ?? "1")
                if let s = sum , sum! > 1 {
                    self.pageSum = s
                }
            }
            print("page:\(currentPage) sum:\(pageSum)")
            
            //解析评论列表
            for comment in comments {
                var pid: String?
                if let spid = comment["id"]  { //pid23224562
                    pid = String(spid [spid.range(of: "pid")!.upperBound...])
                } else {
                    // pid 都没有和咸鱼有什么区别
                    continue
                }
                
                var have = false
                if datas.count > 0 {
                    //过滤重复的
                    for i in (0 ..< datas.count).reversed() {
                        if datas[i].pid == pid {
                            have = true
                            break
                        }
                    }
                }
                if have { continue }
                
                // ==data==
                var author: String?
                var uid: String?
                var index: String?
                var time: String?
                
                if let au = comment.xpath("div/ul/li[1]/b/a").first {
                    author = au.text
                    uid = String(Utils.getNum(from: au["href"] ?? "0") ?? 0)
                }
                
                if let indexNode = comment.xpath("div/ul/li[1]/em").first {
                    index = indexNode.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n"))
                }
                if let timeNode = comment.xpath("div/ul/li[2]").first {
                    time = timeNode.text?.replacingOccurrences(of: "收藏", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                //层主url
                if self.datas.count > 0 || subDatas.count > 0 {
                    replyUrl = comment.xpath("div/div[2]/input").first?["href"]
                }
                
                let content = comment.xpath("div/div[1]").first?.innerHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let c = PostData(content: content ?? "获取内容失败", author: author ?? "未知作者",
                                 uid: uid ?? "0", time: time ?? "未知时间",
                                 pid: pid ?? "0", index: index ?? "#?",replyUrl: replyUrl)
                subDatas.append(c)
            }
        } else { //错误
            //有可能没有列表处理错误
            let errorText = doc.css(".jump_c").first?.text
            print(errorText ?? "网络错误")
            DispatchQueue.main.async {
                self.showBackAlert(message: errorText ?? "帖子不存在")
            }
        }
        
        if !self.saveToHistory && subDatas.count > 0 && self.currentPage == 1{
            DispatchQueue.main.async {
                self.saveToHistory(tid: String(self.tid!), title: self.contentTitle ?? "未知标题", author: subDatas[0].author, created: subDatas[0].time)
                self.saveToHistory = true
            }
        }
        
        return subDatas
    }
    
    
    // textview 链接点击事件
    // textView.delegate = self
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(URL.absoluteString)
        return false
    }
    
    private func showBackAlert(message: String) {
        let alert = UIAlertController(title: "无法打开帖子", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "关闭", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    private func showAlert(title:String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "好", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    // 保存到历史记录
    private func saveToHistory(tid:String,title:String,author:String?,created:String?){
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchOffset = 0
        let entity = NSEntityDescription.entity(forEntityName: "History", in: context)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate.init(format: "tid = '\(String(describing: tid))'", "")
        fetchRequest.predicate = predicate
        
        let fetchedObjects = try? context.fetch(fetchRequest) as? [History]
        if fetchedObjects != nil && fetchedObjects!!.count > 0 {
            for one in fetchedObjects!! {
                print("update history...")
                one.title = title
                one.author = author
                one.created = created
                one.time = Int64(Date().timeIntervalSince1970)
                app.saveContext()
            }
        } else {
            print("insert to history...")
            let insert = NSEntityDescription.insertNewObject(forEntityName: "History", into:context) as! History
            insert.tid = tid
            insert.title = title
            insert.author = author
            insert.created = created
            insert.time = Int64(Date().timeIntervalSince1970)
            app.saveContext()
        }
    }
    
    
    @objc func avatarClick(_ sender : UITapGestureRecognizer)  {
        self.performSegue(withIdentifier: "postToUserDetail", sender: sender.view?.superview?.superview)
    }
    
    
    //显示更多按钮
    @IBAction func shareBtnClick(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "浏览器中打开", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: self.getUrl(page: self.currentPage))! ,
                                      options: [:], completionHandler: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "收藏文章", style: .default, handler: { (UIAlertAction) in
            print("star click")
            PostViewController.doStarPost(tid: self.tid!, callback: { (ok, res) in
                self.showAlert(title: ok ? "收藏成功!" : "收藏错误", message: res)
            })
        }))
        
        sheet.addAction(UIAlertAction(title: "分享文章", style: .default, handler: { (UIAlertAction) in
            print("share click")
            let shareVc =  UIActivityViewController(activityItems: [UIActivityType.copyToPasteboard], applicationActivities: nil)
            shareVc.setValue(self.contentTitle, forKey: "subject")
            self.present(shareVc, animated: true, completion: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (UIAlertAction) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    // 收藏
    public static func doStarPost(tid:Any,callback:@escaping (Bool,String)-> Void) {
        HttpUtil.POST(url: Urls.addStarUrl(tid: tid), params:["favoritesubmit":"true"]) { (ok, res) in
            if ok {
                if res.contains("成功") || res.contains("您已收藏") {
                    callback(true,"收藏成功")
                    return
                }
            }
            callback(false,"网络不太通畅,请稍后重试")
        }
    }
    
    // 评论层主
    @objc func replyCzClick(_ sender:UIButton) {
        if let indexPath = self.tableView.indexPath(for: sender.superview!.superview as! UITableViewCell),
            let _ = datas[indexPath.row].replyUrl {
            replyBoxView.showInputBox(context: self, title: "回复:\(datas[indexPath.row].index) \(datas[indexPath.row].author)", isLz: false,pos: indexPath.row)
        }
    }
    
    // 评论
    @IBAction func commentClick(_ sender: UIBarButtonItem) {
        print("commentClick")
        if !App.isLogin {
            let alert = UIAlertController(title: "需要登陆", message: "你需要登陆才回帖", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "登陆", style: .default, handler: { (alert) in
                let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
                self.present(dest!, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if datas.count == 0 || datas[0].replyUrl == nil {
            showAlert(title: "提示", message: "本帖不支持回复")
        } else {
            replyBoxView.showInputBox(context: self, title: "回复:楼主 \(datas[0].author)", isLz: true)
        }
    }
    
    // do 回复楼主/层主
    func doReply(islz:Bool, message:String, pos:Int) {
        replyBoxView.startLoading()
        if islz {
            HttpUtil.POST(url: datas[0].replyUrl!, params: ["message":message,"handlekey":"fastpost","loc":1,"inajax":1], callback: self.handleReplyResult)
        }else {
            guard let url = datas[pos].replyUrl else { replyBoxView.endLoading(); return }
            //1.根据replyUrl获得相关参数
            print("url:\(url)")
            HttpUtil.GET(url:url, params: nil, callback: { (ok, res) in
                //print(res)
                if ok,let doc = try? HTML(html: res, encoding: .utf8) {
                    //*[@id="postform"]
                    print("=======")
                    if let url = doc.xpath("//*[@id=\"postform\"]").first?["action"] {
                        var parameters = ["message":message]
                        //*[@id="formhash"]
                        let inputs = doc.xpath("//*[@id=\"postform\"]/input")
                        for input in inputs {
                            parameters[input["name"]!] = input["value"]!
                        }
                        
                        //2. 正式评论层主
                        print("postCzUrl:\(url)")
                        print("parameters:\(parameters)")
                        HttpUtil.POST(url: url, params: parameters, callback: self.handleReplyResult)
                        return
                    }
                }
                
                //处理未成功加载的楼层回复
                DispatchQueue.main.async { [weak self] in
                    self?.replyBoxView.endLoading()
                    self?.showAlert(title: "回复失败", message: "回复失败,请稍后重试")
                }
            })
            
        }
    }
    
    func handleReplyResult(ok:Bool,res:String) {
        var success = false
        var reason:String
        if ok {
            if res.contains("成功") || res.contains("层主") || res.contains("class=\"postlist\"") {
                success = true
                reason = "回复发表成功"
            }else if res.contains("您两次发表间隔"){
                reason = "您两次发表间隔太短了,请稍后重试"
            }else if res.contains("主题自动关闭") {
                reason = "此主题已关闭回复,无法回复"
            }else if res.contains("字符的限制"){
                reason = "抱歉，您的帖子小于 13 个字符的限制"
            } else {
                print(res)
                reason = "由于未知原因发表失败"
            }
        }else {
            reason = "连接超时,请稍后重试"
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.replyBoxView.endLoading()
            if !success {
                self?.showAlert(title: "回复失败", message: reason)
            }else {
                self?.replyBoxView.hideInputBox(clear: true)
                let alert = UIAlertController(title: nil, message: reason, preferredStyle: .alert)
                self?.present(alert, animated: true)
                let duration: Double = 1.5
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration){
                    alert.dismiss(animated: true)
                }
                
                if self?.currentPage == 1 {
                    self?.refreshData()
                }
            }
        }
    }
    
    @IBAction func refreshClick(_ sender: UIBarButtonItem) {
        refreshData()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UserDetailViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            if let uid = Int(datas[index.row].uid) {
                dest.uid = uid
                dest.username = datas[index.row].author
            }
        }
    }
}
