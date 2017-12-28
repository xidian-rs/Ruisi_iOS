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
// TODO 根据pid参数跳转到指定页，当用户从消息页面点击进来，有pid参数，默认打开回复用户的那一页
class PostViewController: UIViewController {
    
    var tid: Int? // 由前一个页面传过来的值
    var pid: Int? // TODO
    var saveToHistory = false //是否保存到历史记录
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var replyView: SimpleReplyView! ////回复框view
    
    private lazy var rsRefreshControl = RSRefreshControl()
    private var datas = [PostData]()
    private var currentPage: Int = 1
    private var pageSum: Int = 1
    private var albums = [AlbumData]()
    private var lastLoad: UInt64 = 0
    private var replyLzUrl: String? //回复楼主的地址
    private var tableViewWidth: CGFloat = 0
    
    private var loading = false
    open var isLoading: Bool {
        get {
            return loading
        }
        set {
            loading = newValue
            if !loading {
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
        tableViewWidth = tableView.frame.width
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(moreClick))]
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
        
        setUpHeaderView(title: title)
        self.title = "帖子正文"
        
        //回复框回调
        self.replyView.contentView.isEditable = false
        self.replyView.placeholder = "回复内容"
        self.replyView.enableTail = true
        self.replyView.minTextLen = 13
        
        // 回复楼主
        replyView.onSubmitClick { content in
            if content.trimmingCharacters(in: CharacterSet.whitespaces).count > 0 {
                print("message is:||\(content)||len:\(content.count)")
                self.replyView.isSending = true
                HttpUtil.POST(url: self.replyLzUrl!, params: ["message": content, "handlekey": "fastpost", "loc": 1, "inajax": 1], callback: self.handleReplyResult)
            }
        }
        
        //@ 功能
        replyView.onAtClick { (textView, haveAt) in
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "chooseFriendViewNavigtion") as! UINavigationController
            if let vc = dest.topViewController as? ChooseFriendViewController {
                vc.delegate = { names in // 选择过后调用
                    var result: String = ""
                    names.forEach { (name) in
                        result += " @\(name)"
                    }
                    if names.count > 0 {
                        result += " "
                    }
                    
                    if haveAt {
                        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                    }
                    
                    textView.insertText(result)
                    textView.resignFirstResponder()
                }
                self.present(dest, animated: true, completion: nil)
            }
        }
        
        tableView.addSubview(rsRefreshControl)
        rsRefreshControl.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        rsRefreshControl.beginRefreshing()
        loadData()
    }
    
    //刷新数据
    @objc func reloadData() {
        print("refresh click")
        currentPage = 1
        loadData()
    }
    
    
    func loadData() {
        // 所持请求的数据正在加载中/未加载
        if isLoading {
            return
        }
        isLoading = true
        let url =  Urls.getPostUrl(tid: tid!) + "&page=\(currentPage)"
        print("load data page:\(currentPage) sumPage:\(pageSum)")
        HttpUtil.GET(url: url, params: nil) { [weak self] ok, res in
            guard let this = self else { return }
            var title: String?
            var subDatas: [PostData] = []
            if ok { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    // load fromHash
                    let exitNode = doc.xpath("/html/body/div[@class=\"footer\"]/div/a[2]").first
                    if let hash = Utils.getFormHash(from: exitNode?["href"]) {
                        App.formHash = hash
                    }
                    
                    // load title
                    if let t = doc.title, let index = t.range(of: "-")?.lowerBound {
                        title = String(t[..<index])
                    }
                    
                    //load subdata
                    subDatas = this.parseData(doc: doc, title: title)
                }
            }
            
            //人为加长加载的时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let this = self else { return }
                this.setUpHeaderView(title: title)
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
                
                if this.replyLzUrl == nil { //不支持回复
                    this.replyView.placeholder = "本帖不支持回复(已关闭,没有权限\(App.isLogin ? "" : ",未登陆"))"
                    this.replyView.contentView.isEditable = false
                } else {
                    this.replyView.placeholder = "回复楼主:\(this.datas[0].author)"
                    this.replyView.contentView.isEditable = true
                }
                
                this.isLoading = false
                this.rsRefreshControl.endRefreshing(message: ok ? "加载成功": "加载失败")
            }
        }
    }
    
    // 风扇策略比较保守，温度很低就开始转了，其余还行
    
    // 子类重写此方法支持解析自己的数据
    func parseData(doc: HTMLDocument,title: String?) -> [PostData] {
        var subDatas: [PostData] = []
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
                //第一页是全更新不过滤
                if self.currentPage > 1 && datas.count > 0 {
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
                let content = comment.xpath("div/div[1]").first?.innerHTML?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "获取内容失败"
                let attrContent = AttributeConverter(font: UIFont.systemFont(ofSize: 16), textColor: UIColor.darkText).convert(src: content)
                let c = PostData(content: attrContent, author: author ?? "未知作者",
                                 uid: uid ?? 0, time: time ?? "未知时间",
                                 pid: pid ?? 0, index: index ?? "#?", replyUrl: replyCzUrl)
                //计算行高
                c.rowHeight = caculateRowheight(width: self.tableViewWidth, content: attrContent)
                subDatas.append(c)
            }
            
            if subDatas.count > 0 {
                self.saveToHistory(tid: String(self.tid!), title: title ?? "未知标题", author: subDatas[0].author, created: subDatas[0].time)
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
            SQLiteDatabase.instance?.addHistory(tid: Int(tid)!, title: title, author: author ?? "未知作者", created: created ?? "")
        }
    }
    
    
    // 设置headerView 显示标题
    private var isSetHeaderView = false
    func setUpHeaderView(title: String?) {
        if isSetHeaderView { return }
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        if let t = title {
            isSetHeaderView = true
            label.text = t
        } else {
            label.text = "未知帖子标题"
        }
        
        let height = label.textHeight(for: tableView.bounds.width - 30)
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height + 20))
        label.frame = CGRect(x: 15, y: 12, width: tableView.bounds.width - 30, height: height + 8)
        headerView.addSubview(label)
        
        tableView.tableHeaderView = headerView
        
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
            shareVc.setValue(self.title, forKey: "subject")
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
        } else if segue.identifier == "toReplyCzController" ,let nav = segue.destination as? UINavigationController,let dest = nav.topViewController as? ReplyCzViewController, let data = sender as? PostData {
            dest.title = "回复:\(data.index) \(data.author)"
            dest.data = data
        }
    }
    
    
    // 返回到本vc
    @IBAction func backToPostVc(segue: UIStoryboardSegue) {
        // TODO 回复层主页面返回判断回复状态
        if let vc = segue.source as? ReplyCzViewController {
            print("reply cz :\(vc.isSuccess)")
        }
    }
    
    // MARK: html text里面的链接点击事件
    func linkClick(type: LinkClickType) {
        switch type {
        case .viewUser(let uid):
            self.performSegue(withIdentifier: "postToUserDetail", sender: uid)
        case .viewAlbum(let (aid, url)):
            showAlbums(aid: aid, url: url)
        case .viewPost(let (tid, pid)):
            if pid == self.pid { // 点击了跳转到本帖的url
                for i in 0..<datas.count {
                    if datas[i].pid == pid {
                        self.tableView.scrollToRow(at: IndexPath.init(row: i, section: 0), at: .top, animated: true)
                        break
                    }
                }
            } else { // 点击了跳转到别的帖子的url打开新的页面
                let vc = PostViewController()
                vc.tid = tid
                vc.pid = pid
                self.show(vc, sender: true)
            }
        case .login():
            let vc = LoginViewController()
            self.present(vc, animated: true)
        case .others(let url), .attachment(let url):
            if let u = URL(string: url) {
                self.loadWebView(title: nil, url: u)
            }
        default:
            break
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
        if datas.count == 0 {
            tableView.tableFooterView?.isHidden = true
            return 0
        } else {
            tableView.tableFooterView?.isHidden = false
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data: PostData
        let cell: UITableViewCell
        
        data = datas[indexPath.row]
        cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let index = cell.viewWithTag(6) as! UILabel
        index.text = data.index
        let replyBtn = cell.viewWithTag(7) as? UIButton
        if data.replyUrl != nil {
            replyBtn?.isHidden = false
            replyBtn?.addTarget(self, action: #selector(replyCzClick(_:)), for: .touchUpInside)
        } else {
            replyBtn?.isHidden = true
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
        
        content.attributedText =  data.content
        content.linkClickDelegate = self.linkClick
        
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = datas[indexPath.row]
        return d.rowHeight
    }
    
    // 计算行高
    private func caculateRowheight(width: CGFloat, content: NSAttributedString) -> CGFloat {
        let contentHeight = content.height(for: self.tableViewWidth - 30)
        return 12 + 36 + 6 + contentHeight + 10
    }
}

// MARK: - 评论相关
extension PostViewController {
    // 评论层主 // TODO 新的页面。。。。
    @objc func replyCzClick(_ sender: UIButton) {
        if let indexPath = self.tableView.indexPath(for: sender.superview!.superview as! UITableViewCell),
            datas[indexPath.row].replyUrl != nil {
            self.performSegue(withIdentifier: "toReplyCzController", sender: datas[indexPath.row])
            //let y1 = tableView.cellForRow(at: indexPath)!.frame.maxY - tableView.contentOffset.y
            //let y2 = view.bounds.height - AboveKeyboardView.keyboardHeight - replyView.frame.height //(44--toolbarView)
            //if y1 > y2 {
            //    tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + (y1 - y2)), animated: true)
            //}
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
                    self?.loadData()
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


