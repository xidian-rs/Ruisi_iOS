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
class PostViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var replyBoxView: ReplyBoxView!
    
    var datas = [PostData]()
    var tid: Int? // 由前一个页面传过来的值
    var saveToHistory = false //是否保存到历史记录
    var contentTitle: String?
    
    private var currentPage: Int = 1
    private var pageSum: Int = 1
    private var refreshView: UIRefreshControl!
    private var albums = [AlbumData]()
    
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
            if currentPage >= pageSum { return } // TODO 最后一页是否还要继续刷新
            if currentPage < pageSum { currentPage += 1 }
            print("load more next page is:\(currentPage) sum is:\(pageSum)")
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
        let content = cell.viewWithTag(5) as! HtmlTextView
        let editBtn = cell.viewWithTag(8) as! UIButton
        
        if App.uid != nil && App.uid! == data.uid && data.pid > 0 {
            editBtn.isHidden = false
            editBtn.addTarget(self, action: #selector(editClick(_:)), for: .touchUpInside)
        }else {
            editBtn.isHidden = true
        }
        
        lz.isHidden = datas[0].author != data.author
        author.text = data.author
        time.text = data.time
        img.kf.setImage(with:  Urls.getAvaterUrl(uid: data.uid))
        img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick(_:))))
        content.htmlViewDelegate = self.linkClick
        content.text = data.content
        return cell
    }
    

    func loadData() {
        // 所持请求的数据正在加载中/未加载
        if isLoading { return }
        refreshView.attributedTitle = NSAttributedString(string: "正在加载")
        isLoading = true
        print("load data page:\(currentPage) sumPage:\(pageSum)")
        HttpUtil.GET(url: getUrl(page: currentPage), params: nil) { ok, res in
            //print(res)
            var str:String?
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
                let df =  DateFormatter()
                df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                str = "Last update: "+df.string(from: Date())
            }else {
                str = "加载失败"
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                if subDatas.count > 0 {
                    if self.currentPage == 1 {
                        self.datas = subDatas
                        self.tableView.reloadData()
                    }else {
                        var indexs = [IndexPath]()
                        for i in 0..<subDatas.count {
                            indexs.append(IndexPath(row: self.datas.count + i, section: 0))
                        }
                        self.datas.append(contentsOf: subDatas)
                        print("here :\(subDatas.count)")
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: indexs, with: .automatic)
                        self.tableView.endUpdates()
                    }
                }else {
                    //第一次没有加载到数据
                    if self.currentPage == 1 {
                        self.tableView.reloadData()
                    }
                }
                
                let attrStr = NSAttributedString(string: str ?? "", attributes: [NSAttributedStringKey.foregroundColor:UIColor.gray])
                self.tableView.refreshControl?.attributedTitle = attrStr
                self.isLoading = false
            })
            
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
                var pid: Int?
                if let spid = comment["id"]  { //pid23224562
                    pid = Int(String(spid [spid.range(of: "pid")!.upperBound...]))
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
                if self.datas.count > 0 || subDatas.count > 0 {
                    replyUrl = comment.xpath("div/div[2]/input").first?["href"]
                }
                
                let content = comment.xpath("div/div[1]").first?.innerHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let c = PostData(content: content ?? "获取内容失败", author: author ?? "未知作者",
                                 uid: uid ?? 0, time: time ?? "未知时间",
                                 pid: pid ?? 0, index: index ?? "#?",replyUrl: replyUrl)
                subDatas.append(c)
            }
            
            if subDatas.count > 0 {
                self.saveToHistory(tid: String(self.tid!), title: self.contentTitle ?? "未知标题", author: subDatas[0].author, created: subDatas[0].time)
            }
        } else { //错误
            //有可能没有列表处理错误
            let errorText = doc.css(".jump_c").first?.text
            print(errorText ?? "网络错误")
            DispatchQueue.main.async {
                self.showBackAlert(message: errorText ?? "帖子不存在")
            }
        }
        
        
        return subDatas
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
        if self.saveToHistory { return }
        self.saveToHistory = true
        DispatchQueue.global(qos: .background).async {
            SQLiteDatabase.instance?.addHistory(tid: Int(tid)!, title: title, author: author ?? "未知作者", created: created ?? "")
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
        
        
        sheet.addAction(UIAlertAction(title: "收藏文章", style: .default, handler: { action in
            print("star click")
            PostViewController.doStarPost(tid: self.tid!, callback: { (ok, res) in
                self.showAlert(title: ok ? "收藏成功!" : "收藏错误", message: res)
            })
        }))
        
        sheet.addAction(UIAlertAction(title: "分享文章", style: .default, handler: { action in
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
            datas[indexPath.row].replyUrl != nil {
            replyBoxView.showInputBox(context: self, title: "回复:\(datas[indexPath.row].index) \(datas[indexPath.row].author)", isLz: false,pos: indexPath.row)
        }
    }
    
    // 编辑帖子
    @objc func editClick(_ sender:UIButton) {
        if let indexPath = self.tableView.indexPath(for: sender.superview!.superview as! UITableViewCell) {
            if datas[indexPath.row].pid > 0 {
                self.performSegue(withIdentifier: "postToEditController", sender: indexPath)
            }
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
    

    // html text里面的链接点击事件
    func linkClick(type: LinkClickType) {
        switch type {
        case .viewUser(let uid):
            self.performSegue(withIdentifier: "postToUserDetail", sender: uid)
        case .viewAlbum(let (aid, url)) :
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
            }else if let uid = sender as? Int {
                dest.uid = uid
            }
        } else if let dest = segue.destination as? NewPostViewController,let index = sender as? IndexPath {
            dest.isEditMode = true
            dest.tid = self.tid
            dest.pid = datas[index.row].pid
        }
    }
    
    private var isLoadingAlbums = false
    private var isLoadedAlbums = false
    private var currentFetch: ((UIImage?) -> Void)?
    
    
    private func showAlbums(aid: Int, url: String) {
        if self.albums.count > 0 {
            self.showViewerController(aid: aid)
            return
        }
        
        if isLoadingAlbums || isLoadedAlbums { return }
        isLoadingAlbums = true
        
        self.showViewerController(aid: nil)
        HttpUtil.GET(url: url, params: nil, callback: { (ok, res) in
            self.isLoadingAlbums = false
            self.isLoadedAlbums = true
            if ok, let doc = try? HTML(html: res, encoding: .utf8) {
                self.albums.removeAll()
                for li in  doc.css("ul.postalbum_c li") {
                    if let src = li.css("img").first?["src"] ?? li.css("img").first?["zsrc"] {
                        self.albums.append(AlbumData(aid: Utils.getNum(prefix: "aid=", from: src)!, src: Urls.baseUrl + src))
                    }
                }
                
                if self.albums.count <= 0 { return }
                var index: Int = 0
                for (k, v) in self.albums.enumerated() {
                    if v.aid == aid {
                        index = k
                        break
                    }
                }
                
                if let compete = self.currentFetch {
                    let task =  URLSession.shared.dataTask(with: URL(string: self.albums[index].src)! , completionHandler: { (data, response, error) in
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
        let galleryViewController = GalleryViewController(startIndex: index, itemsDataSource: self, displacedViewsDataSource: self)
        self.present(galleryViewController, animated: false, completion: nil)
    }
}



extension PostViewController: GalleryDisplacedViewsDataSource, GalleryItemsDataSource {
    // 提供动画开始的view
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        //return index < items.count ? items[index].imageView : nil
        return nil
    }
    
    func provideGalleryItem(_ index: Int) -> FetchImageBlock {
        return  { imageCompletion in
            self.currentFetch = imageCompletion
            if index <=  self.albums.count - 1 {
                let url = self.albums[index].src
                let task =  URLSession.shared.dataTask(with: URL(string: url)! , completionHandler: { (data, response, error) in
                    if let d = data {
                        imageCompletion(UIImage(data: d))
                    }
                })
                task.resume()
            }
        }
    }
    
    
    func itemCount() -> Int {
        return (albums.count == 0) ? 1 : albums.count
    }
}


