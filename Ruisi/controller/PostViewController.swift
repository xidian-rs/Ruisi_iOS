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
// 判断帖子作者的逻辑目前有问题
class PostViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var replyView: SimpleReplyView! ////回复框view
    
    var datas = [PostData]()
    var tid: Int? // 由前一个页面传过来的值
    var saveToHistory = false //是否保存到历史记录
    var postTitle: String? // 文章标题
    
    private var currentPage: Int = 1
    private var pageSum: Int = 1
    private var refreshView: UIRefreshControl!
    private var albums = [AlbumData]()
    private var lastLoad: UInt64 = 0
    private var replyLzUrl: String? //回复楼主的地址
    
    private var loading = false
    open var isLoading: Bool {
        get {
            return loading
        }
        set {
            loading = newValue
            if !loading {
                refreshView.endRefreshing()
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading(haveMore: currentPage < pageSum)
                }
            } else {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.startLoading()
                }
            }
        }
    }
    
    // close
    // self.navigationController?.popViewController(animated: true)
    override func viewDidLoad() {
        if tid == nil {
            showBackAlert(title: "无法查看帖子", message: "没有传入tid参数")
            return
        }
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(moreClick))]
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
        
        // Initialize the refresh control.
        refreshView = UIRefreshControl()
        Widgets.setRefreshControl(refreshView)
        refreshView.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshView
        refreshView.beginRefreshing()
        
        self.postTitle = self.title
        self.title = "帖子正文"
        
        //回复框回调
        self.replyView.placeholder = "发表评论"
        self.replyView.contentView.isEditable = false
        replyView.onSubmitClick { (content, userinfo) in
            if content.trimmingCharacters(in: CharacterSet.whitespaces).count > 0 {
                print("message is:||\(content)||len:\(content.count)")
                self.doReply(content: content, userinfo: userinfo)
            }
        }
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
    }
    
    //刷新数据
    @objc func refreshData() {
        print("refresh click")
        currentPage = 1
        pageSum = Int.max
        loadData()
    }
    
    
    func loadData() {
        // 所持请求的数据正在加载中/未加载
        if isLoading {
            return
        }
        refreshView.attributedTitle = NSAttributedString(string: "正在加载")
        isLoading = true
        let url =  Urls.getPostUrl(tid: tid!) + "&page=\(currentPage)"
        print("load data page:\(currentPage) sumPage:\(pageSum)")
        HttpUtil.GET(url: url, params: nil) { [weak self] ok, res in
            guard let this = self else { return }
            var str: String?
            var subDatas: [PostData] = []
            if ok { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    // load fromHash
                    let exitNode = doc.xpath("/html/body/div[@class=\"footer\"]/div/a[2]").first
                    if let hash = Utils.getFormHash(from: exitNode?["href"]) {
                        App.formHash = hash
                    }
                    
                    //load subdata
                    subDatas = this.parseData(doc: doc)
                }
                let df = DateFormatter()
                df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                str = "Last update: " + df.string(from: Date())
            } else {
                str = "加载失败"
            }
            
            //人为加长加载的时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let this = self else { return }
                if subDatas.count > 0 {
                    if this.currentPage == 1 {
                        this.datas = subDatas
                        this.tableView.reloadData()
                    } else {
                        var indexs = [IndexPath]()
                        for i in 0..<subDatas.count {
                            indexs.append(IndexPath(row: this.datas.count + i, section: 0))
                        }
                        this.datas.append(contentsOf: subDatas)
                        this.tableView.beginUpdates()
                        this.tableView.insertRows(at: indexs, with: .automatic)
                        this.tableView.endUpdates()
                    }
                } else {
                    //第一次没有加载到数据
                    if this.currentPage == 1 {
                        this.tableView.reloadData()
                    }
                }
                
                let attrStr = NSAttributedString(string: str ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
                this.tableView.refreshControl?.attributedTitle = attrStr
                this.isLoading = false
                if self?.replyLzUrl == nil { //不支持回复
                    self?.replyView.placeholder = "本帖不支持回复(已关闭,没有权限\(App.isLogin ? "" : ",未登陆"))"
                    self?.replyView.contentView.isEditable = false
                } else {
                    self?.replyView.placeholder = "发表评论"
                    self?.replyView.contentView.isEditable = true
                }
            }
        }
    }
    
    // 子类重写此方法支持解析自己的数据
    func parseData(doc: HTMLDocument) -> [PostData] {
        var subDatas: [PostData] = []
        if self.postTitle == nil, let t = doc.title {
            self.postTitle = String(t[..<t.index(of: " - ")!])
        }
        
        let comments = doc.xpath("/html/body/div[1]/div[@class=\"plc cl\"]")
        if comments.count > 0 {
            //获取总页数 和当前页数
            if let pg = doc.css(".pg").first {
                // var page = Utils.getNum(from: pg.css("strong").first?.text ?? "1")
                let sum = Utils.getNum(from: pg.css("span").first?["title"] ?? "1")
                if let s = sum, sum! > 1 {
                    self.pageSum = s
                }
            }
            print("page:\(currentPage) sum:\(pageSum)")
            //获得回复楼主的url 为nil不显示评论框
            replyLzUrl = (doc.innerHTML?.contains("您暂时没有权限发表") ?? false) ? nil : doc.xpath("//*[@id=\"fastpostform\"]").first?["action"]
            //解析评论列表
            for comment in comments {
                var pid: Int?
                if let spid = comment["id"] { //pid23224562
                    pid = Int(String(spid[spid.range(of: "pid")!.upperBound...]))
                } else {
                    // pid 都没有和咸鱼有什么区别
                    continue
                }
                
                var have = false
                if datas.count > 0 {
                    //过滤重复的
                    for i in (0..<datas.count).reversed() {
                        if datas[i].pid == pid {
                            have = true
                            break
                        }
                    }
                }
                if have {
                    continue
                }
                
                // ==data==
                var author: String?
                var uid: Int?
                var index: String?
                var time: String?
                
                if let au = comment.xpath("div/ul/li[1]/b/a").first {
                    author = au.text
                    uid = Utils.getNum(from: au["href"] ?? "0") ?? 0
                }
                
                if let indexNode = comment.xpath("div/ul/li[1]/em").first {
                    index = indexNode.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n"))
                }
                if let timeNode = comment.xpath("div/ul/li[2]").first {
                    time = timeNode.text?.replacingOccurrences(of: "收藏", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                //层主url
                let replyCzUrl = comment.xpath("div/div[2]/input").first?["href"]
                let content = comment.xpath("div/div[1]").first?.innerHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
                let c = PostData(content: content ?? "获取内容失败", author: author ?? "未知作者",
                                 uid: uid ?? 0, time: time ?? "未知时间",
                                 pid: pid ?? 0, index: index ?? "#?", replyUrl: replyCzUrl)
                subDatas.append(c)
            }
            
            if subDatas.count > 0 {
                self.saveToHistory(tid: String(self.tid!), title: self.postTitle ?? "未知标题", author: subDatas[0].author, created: subDatas[0].time)
            }
        } else { //错误
            //有可能没有列表处理错误
            let errorText = doc.css(".jump_c").first?.text
            print(errorText ?? "网络错误")
            DispatchQueue.main.async {
                self.showBackAlert(title: "无法查看帖子", message: errorText ?? "帖子不存在")
            }
        }
        return subDatas
    }
    
    
    // 保存到历史记录
    private func saveToHistory(tid: String, title: String, author: String?, created: String?) {
        if self.saveToHistory {
            return
        }
        self.saveToHistory = true
        DispatchQueue.global(qos: .background).async {
            SQLiteDatabase.instance?.addHistory(tid: Int(tid)!, title: self.postTitle ?? "未知标题帖子", author: author ?? "未知作者", created: created ?? "")
        }
    }
    
    
    @objc func avatarClick(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "postToUserDetail", sender: sender.view?.superview?.superview)
    }
    
    
    //显示更多按钮
    @objc func moreClick(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "浏览器中打开", style: .default) { action in
            UIApplication.shared.open(URL(string: Urls.getPostUrl(tid: self.tid!) + "&page=\(self.currentPage)")!)
        })
        sheet.addAction(UIAlertAction(title: "收藏文章", style: .default) { action in
            print("star click")
            PostViewController.doStarPost(tid: self.tid!, callback: { (ok, res) in
                self.showAlert(title: ok ? "收藏成功!" : "收藏错误", message: res)
            })
        })
        sheet.addAction(UIAlertAction(title: "分享文章", style: .default) { action in
            print("share click")
            let shareVc = UIActivityViewController(activityItems: [UIActivityType.copyToPasteboard], applicationActivities: nil)
            shareVc.setValue(self.postTitle, forKey: "subject")
            self.present(shareVc, animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: "关闭", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }
    
    // 收藏
    public static func doStarPost(tid: Any, callback: @escaping (Bool, String) -> Void) {
        HttpUtil.POST(url: Urls.addStarUrl(tid: tid), params: ["favoritesubmit": "true"]) { (ok, res) in
            if ok {
                if res.contains("成功") || res.contains("您已收藏") {
                    callback(true, "收藏成功")
                    return
                }
            }
            callback(false, "网络不太通畅,请稍后重试")
        }
    }
    
    
    // 编辑帖子
    @objc func editClick(_ sender: UIButton) {
        if let indexPath = self.tableView.indexPath(for: sender.superview!.superview as! UITableViewCell) {
            if datas[indexPath.row].pid > 0 {
                self.performSegue(withIdentifier: "postToEditController", sender: indexPath)
            }
        }
    }
    
    
    // html text里面的链接点击事件
    func linkClick(type: LinkClickType) {
        switch type {
        case .viewUser(let uid):
            self.performSegue(withIdentifier: "postToUserDetail", sender: uid)
        case .viewAlbum(let (aid, url)):
            showAlbums(aid: aid, url: url)
        default:
            break
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UserDetailViewController {
            if let cell = sender as? UITableViewCell {
                let index = tableView.indexPath(for: cell)!
                if datas[index.row].uid > 0 {
                    dest.uid = datas[index.row].uid
                    dest.username = datas[index.row].author
                }
            } else if let uid = sender as? Int {
                dest.uid = uid
            }
        } else if let dest = segue.destination as? NewPostViewController, let index = sender as? IndexPath {
            dest.isEditMode = true
            dest.tid = self.tid
            dest.pid = datas[index.row].pid
        }
    }
    
    private var isLoadingAlbums = false
    private var isLoadedAlbums = false
    private var currentFetch: ((UIImage?) -> Void)?
}

// MARK: - tableview相关
extension PostViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data: PostData
        let cell: UITableViewCell
        if indexPath.row == 0 {
            data = datas[0]
            cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath)
            let title = cell.viewWithTag(6) as! UILabel
            title.text = postTitle ?? self.title
        } else {
            data = datas[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath)
            let index = cell.viewWithTag(6) as! UILabel
            index.text = data.index
            let replyBtn = cell.viewWithTag(7) as? UIButton
            if data.replyUrl != nil {
                replyBtn?.isHidden = false
                replyBtn?.addTarget(self, action: #selector(replyCzClick(_:)), for: .touchUpInside)
            } else {
                replyBtn?.isHidden = true
            }
        }
        
        let img = cell.viewWithTag(1) as! UIImageView
        let author = cell.viewWithTag(2) as! UILabel
        let lz = cell.viewWithTag(3) as! UILabel
        let time = cell.viewWithTag(4) as! UILabel
        let content = cell.viewWithTag(5) as! HtmlLabel
        let editBtn = cell.viewWithTag(8) as! UIButton
        
        if App.uid != nil && App.uid! == data.uid && data.pid > 0 {
            editBtn.isHidden = false
            editBtn.addTarget(self, action: #selector(editClick(_:)), for: .touchUpInside)
        } else {
            editBtn.isHidden = true
        }
        
        lz.isHidden = datas[0].author != data.author
        author.text = data.author
        time.text = data.time
        img.kf.setImage(with: Urls.getAvaterUrl(uid: data.uid))
        img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick(_:))))
        content.htmlText =  data.content
        //TODO content.htmlViewDelegate = self.linkClick
        
        
        return cell
    }
    
    // load more
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = datas.count - 1
        if !isLoading && indexPath.row == lastElement { //确保8s后再开始加载本页
            if currentPage >= pageSum && (DispatchTime.now().uptimeNanoseconds / 1000000000 - lastLoad < 8) {
                return
            } // TODO 最后一页是否还要继续刷新
            if currentPage < pageSum {
                currentPage += 1
            }
            if currentPage == pageSum {
                lastLoad = DispatchTime.now().uptimeNanoseconds / 1000000000
            }
            loadData()
        }
    }
}

// MARK: - 评论相关
extension PostViewController {
    // 评论楼主 TODO
    @IBAction func commentClick(_ sender: UIBarButtonItem) {
        if checkLogin(message: "你需要登陆才回帖") {
            
        } else if datas.count == 0 || datas[0].replyUrl == nil {
            showAlert(title: "提示", message: "本帖不支持回复")
        }else {
            replyView.showReplyBox(clear: false, placeholder: "回复:楼主 \(datas[0].author)", userinfo: ["isLz": true])
        }
    }
    
    // 评论层主
    @objc func replyCzClick(_ sender: UIButton) {
        if let indexPath = self.tableView.indexPath(for: sender.superview!.superview as! UITableViewCell),
            let url =  datas[indexPath.row].replyUrl {
            
            replyView.showReplyBox(clear: true, placeholder: "回复:\(datas[indexPath.row].index) \(datas[indexPath.row].author)", userinfo: ["url": url])
            
            let y1 = tableView.cellForRow(at: indexPath)!.frame.maxY - tableView.contentOffset.y
            let y2 = view.bounds.height - AboveKeyboardView.keyboardHeight - replyView.frame.height
            
            //print("y1:\(y1)  \(view.bounds.height - 253)")
            if y1 > y2 {
                tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + (y1 - y2)), animated: true)
            }
        }
    }
    
    // do 回复楼主/层主
    private func doReply(content: String, userinfo: [AnyHashable : Any]?) {
        replyView.isSending = true
        if (userinfo?["isLz"]) != nil {
            HttpUtil.POST(url: datas[0].replyUrl!, params: ["message": content, "handlekey": "fastpost", "loc": 1, "inajax": 1], callback: self.handleReplyResult)
        } else {
            let url = userinfo!["url"]! as! String
            //1.根据replyUrl获得相关参数
            print("url:\(url)")
            HttpUtil.GET(url: url, params: nil, callback: { (ok, res) in
                //print(res)
                if ok, let doc = try? HTML(html: res, encoding: .utf8) {
                    //*[@id="postform"]
                    print("=======")
                    if let url = doc.xpath("//*[@id=\"postform\"]").first?["action"] {
                        var parameters = ["message": content]
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
                    self?.replyView.isSending = false
                    self?.replyView.hidekeyboard()
                    self?.showAlert(title: "回复失败", message: "回复失败,请稍后重试")
                }
            })
            
        }
    }
    
    private func handleReplyResult(ok: Bool, res: String) {
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
            self?.replyView.isSending = false
            if !success {
                self?.replyView.hidekeyboard()
                self?.showAlert(title: "回复失败", message: reason)
            } else {
                self?.replyView.clearText(hide: true)
                let alert = UIAlertController(title: nil, message: reason, preferredStyle: .alert)
                self?.present(alert, animated: true)
                let duration: Double = 1.5
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                    alert.dismiss(animated: true)
                }
                
                if self?.currentPage == 1 {
                    self?.refreshData()
                }
            }
        }
    }
}

// MARK: - GalleryItemsDataSource
extension PostViewController: GalleryItemsDataSource {
    private func showAlbums(aid: Int, url: String) {
        if self.albums.count > 0 {
            self.showViewerController(aid: aid)
            return
        }
        
        if isLoadingAlbums || isLoadedAlbums {
            return
        }
        isLoadingAlbums = true
        
        self.showViewerController(aid: nil)
        HttpUtil.GET(url: url, params: nil, callback: { (ok, res) in
            self.isLoadingAlbums = false
            self.isLoadedAlbums = true
            if ok, let doc = try? HTML(html: res, encoding: .utf8) {
                self.albums.removeAll()
                for li in doc.css("ul.postalbum_c li") {
                    if let src = li.css("img").first?["src"] ?? li.css("img").first?["zsrc"] {
                        self.albums.append(AlbumData(aid: Utils.getNum(prefix: "aid=", from: src)!, src: Urls.baseUrl + src))
                    }
                }
                
                if self.albums.count <= 0 {
                    return
                }
                var index: Int = 0
                for (k, v) in self.albums.enumerated() {
                    if v.aid == aid {
                        index = k
                        break
                    }
                }
                
                if let compete = self.currentFetch {
                    let task = URLSession.shared.dataTask(with: URL(string: self.albums[index].src)!, completionHandler: { (data, response, error) in
                        if let d = data {
                            compete(UIImage(data: d))
                        }
                    })
                    task.resume()
                }
            }
        })
    }
    
    private func showViewerController(aid: Int?) {
        var index: Int = 0
        for (k, v) in self.albums.enumerated() {
            if v.aid == aid {
                index = k
                break
            }
        }
        let galleryViewController = GalleryViewController(startIndex: index, itemsDataSource: self)
        self.present(galleryViewController, animated: false, completion: nil)
    }
    
    
    func provideGalleryItem(_ index: Int) -> FetchImageBlock {
        return { imageCompletion in
            self.currentFetch = imageCompletion
            if index <= self.albums.count - 1,let url = URL(string: self.albums[index].src) {
                //let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
                //    if let d = data {
                //        imageCompletion(UIImage(data: d))
                //    }
                //})
                //task.resume()
                ImageDownloader.default.downloadImage(with: url, options: [], progressBlock: nil) {
                    (image, error, url, data) in
                    if let i = image {
                        imageCompletion(i)
                    }
                }
            }
        }
    }
    
    
    func itemCount() -> Int {
        return (albums.count == 0) ? 1 : albums.count
    }
}


