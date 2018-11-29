//
//  PostsViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 帖子列表
class PostsViewController: BaseTableViewController<ArticleListData>,UIViewControllerPreviewingDelegate {

    var fid: Int? // 由前一个页面传过来的值
    var parentFid: Int?
    
    private var isSchoolNet = App.isSchoolNet
    private var subForums = [KeyValueData<String, Int>]()
    private var subForumBtn: UIBarButtonItem!
    private var submitBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        self.autoRowHeight = false
        self.showRefreshControl = true
        self.parentFid = fid
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        subForumBtn = UIBarButtonItem(title: "子分区", style: .plain, target: self, action: #selector(switchSubForum))
        submitBtn = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newPostClick))
        self.navigationItem.rightBarButtonItems = [submitBtn]

        super.viewDidLoad()
    }
    
    override func getUrl(page: Int) -> String {
        let url = Urls.getPostsUrl(fid: fid!) + "&page=\(page)"
        isSchoolNet = !url.contains("mobile")
        return url
    }
    
    
    // 是不是由记录的子分区载入
    @objc private func switchSubForum() {
        guard subForums.count > 0 else {
            self.navigationItem.rightBarButtonItems = [submitBtn]
            return
        }
        
        let alert = UIAlertController(title: "选择分区", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.barButtonItem = subForumBtn
        
        for item in subForums {
            alert.addAction(UIAlertAction(title: item.key, style: .default, handler: { (ac) in
                Settings.setSelectSubForum(fid: self.parentFid!, subForum: Forum(fid: item.value, name: item.key, login: false))
                print("save choosed subforum \(self.parentFid!) -> \(item.value) \(item.key)")
                self.title = item.key
                self.fid = item.value
                self.reloadData()
            }))
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // 子类重写此方法支持解析自己的数据
    override func parseData(pos: Int, doc: HTMLDocument) -> [ArticleListData] {
        var subDatas: [ArticleListData] = []
        if isSchoolNet {
            if (self.currentPage == 1 || self.datas.count == 0) && subForums.count == 0 {
                for item in doc.css("#subforum_\(fid!) table tr h2 a") {
                    guard let fid = Utils.getNum(prefix: "fid=", from: item["href"]!) else {
                        continue
                    }
                    subForums.append(KeyValueData(key: item.text!, value: fid))
                    print("子板块: \(item.text!) fid:\(fid)")
                }
            }
            
            let showZhidin = (currentPage == 1) && Settings.showZhiding
            let nodes = doc.xpath("//*[@id=\"threadlisttableid\"]/tbody")
            for li in nodes {
                if li["id"] == nil || (!showZhidin && li["id"]!.contains("stickthread")) {
                    continue
                }
                let a = li.xpath("tr/th/a[starts-with(@href,\"forum.php?mod=viewthread\")]").first
                let typeNode = li.xpath("tr/th/em/a[starts-with(@href,\"forum.php?mod=forumdisplay\")]").first
                var tid: Int?
                if let u = a?["href"] {
                    tid = Utils.getNum(from: u)
                } else {
                    //没有tid和咸鱼有什么区别
                    continue
                }
                
                var typeName: String?
                if let type = typeNode {
                    typeName = "[" + type.text! + "] "
                }
                
                let title = (typeName == nil ? "" : typeName!) + (a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n ")) ?? "")
                let color = Utils.getHtmlColor(from: a?["style"])
                
                var author: String?
                var uid: Int?
                if let authorNode = li.xpath("tr/td[2]/cite/a").first {
                    author = authorNode.text!
                    uid = Utils.getNum(from: authorNode["href"]!)
                }
                
                let replys = li.xpath("tr/td[3]/a").first?.text
                let views = li.xpath("tr/td[3]/em").first?.text
                let time = li.xpath("tr/td[2]/em/span").first?.text
                let haveImage = li.xpath("tr/th/img").first?["src"]?.contains("image_s.gif") ?? false
                
                let d = ArticleListData(isSchoolNet: true, title: title.count > 0 ? title : "未获取到标题", tid: tid!, author: author ?? "未知作者", replys: replys ?? "0", read: false, haveImage: haveImage, titleColor: color, uid: uid, views: views, time: time)
                d.rowHeight = caculateRowheight(isSchoolNet: true, width: self.tableViewWidth, title: d.title)
                subDatas.append(d)
            }
            if let pg = doc.xpath("//*[@id=\"fd_page_bottom\"]/div[@class=\"pg\"]").first, let sumNode = pg.xpath("label/span").first {
                self.totalPage = Utils.getNum(from: sumNode.text!) ?? self.currentPage
            } else {
                self.totalPage = self.currentPage
            }
        } else {
            if (self.currentPage == 1 || self.datas.count == 0) && subForums.count == 0 {
                for item in doc.xpath("//*[@id=\"subname_list\"]/ul/li") {
                    let a = item.xpath("a").first!
                    guard let fid = Utils.getNum(prefix: "fid=", from: a["href"]!) else {
                        continue
                    }
                    subForums.append(KeyValueData(key: a.text!, value: fid))
                    print("子板块: \(a.text!) fid:\(fid)")
                }
            }
            
            let nodes = doc.css(".threadlist ul li")
            for li in nodes {
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
                if let r = replys {
                    replysStr = r.text
                    a?.removeChild(r)
                }
                if let au = author {
                    authorStr = au.text
                    a?.removeChild(au)
                }
                let img = (li.css("img").first)?["src"]
                var haveImg = false
                if let i = img {
                    haveImg = i.contains("icon_tu.png")
                }
                
                let title = a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n "))
                let color = Utils.getHtmlColor(from: a?["style"])
                let d = ArticleListData(title: title ?? "未获取到标题", tid: tid!, author: authorStr ?? "未知作者", replys: replysStr ?? "0", read: false, haveImage: haveImg, titleColor: color)
                d.rowHeight = caculateRowheight(isSchoolNet: false, width: self.tableViewWidth, title: d.title)
                subDatas.append(d)
            }
            
            if let pg = doc.xpath("/html/body/div[@class=\"pg\"]").first, let sumNode = pg.xpath("label/span").first {
                self.totalPage = Utils.getNum(from: sumNode.text!) ?? self.currentPage
            } else {
                self.totalPage = self.currentPage
            }
        }
        
        print("page total:\(self.totalPage)")
        //从浏览历史数据库读出是否已读
        SQLiteDatabase.instance?.setReadHistory(datas: &subDatas)
        
        if subForums.count > 0 && self.currentPage == 1 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
                guard let this = self else { return }
                // 设置子板块
                if !(this.navigationItem.rightBarButtonItems ?? []).contains(this.subForumBtn) {
                    this.navigationItem.rightBarButtonItems = [this.submitBtn, this.subForumBtn]
                    guard subDatas.count == 0 else {
                        this.subForums.insert(KeyValueData<String, Int>(key: this.title ?? "主版块", value: this.fid!), at: 0)
                        return
                    }
                    let f = Settings.getSelectSubForum(fid: this.parentFid!)
                    var item: KeyValueData<String, Int>?
                    if f != nil {
                        for v in this.subForums {
                            if v.value == f!.fid {
                                item = v
                                break
                            }
                        }
                    }
                    
                    if item == nil {
                        item = this.subForums.first!
                    }
                    
                    print("empty forum auto switch to subforum")
                    this.title = item!.key
                    this.fid = item!.value
                    this.reloadData()
                }
            }
        }
        
        return subDatas
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        if (!datas[indexPath.row].isRead) { // 未读设置为已读
            datas[indexPath.row].isRead = true
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let d = datas[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: d.isSchoolNet ? "cell_edu" : "cell_me", for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let usernameLabel = cell.viewWithTag(2) as! UILabel
        let commentsLabel = cell.viewWithTag(3) as! UILabel
        let haveImageLabel = cell.viewWithTag(4) as! UILabel
        titleLabel.text = d.title
        if d.isRead {
            titleLabel.textColor = UIColor.darkGray
        } else if let color = d.titleColor {
            titleLabel.textColor = color
        } else {
            titleLabel.textColor = UIColor.darkText
        }
        usernameLabel.text = d.author
        commentsLabel.text = d.replyCount
        haveImageLabel.isHidden = !d.haveImage
        
        if d.isSchoolNet {
            let avater = cell.viewWithTag(6) as! UIImageView
            let timeLabel = cell.viewWithTag(5) as! UILabel
            let viewsLabel = cell.viewWithTag(7) as! UILabel
            
            if let uid = d.uid {
                avater.kf.setImage(with: Urls.getAvaterUrl(uid: uid), placeholder: #imageLiteral(resourceName: "placeholder"))
                avater.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick(_:))))
            } else {
                avater.image = #imageLiteral(resourceName:"placeholder")
            }
            
            timeLabel.text = d.time
            viewsLabel.text = d.views ?? "0"
        }
        
        //forceTouch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: cell)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = datas[indexPath.row]
        return d.rowHeight
    }
    
    // 计算行高
    private func caculateRowheight(isSchoolNet: Bool, width: CGFloat, title: String) -> CGFloat {
        let titleHeight = title.height(for: width - 32, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        if isSchoolNet { // 上间距(12) + 正文(计算) + 间距(8) + 头像(36) + 下间距(10)
            return 12 + titleHeight + 8 + 36 + 10
        } else { // 上间距(12) + 正文(计算) + 间距(8) + 昵称(14.5) + 下间距(10)
            return 12 + titleHeight + 8 + 14.5 + 10
        }
    }
    
    @objc func avatarClick(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "postsToUserDetail", sender: sender.view?.superview?.superview)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let starBtn = UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "收藏", handler: { action, indexpath in
            self.doStarPost(tid: self.datas[indexPath.row].tid)
        })
        starBtn.backgroundColor = UIColor.orange
        return [starBtn]
    }
    
    func doStarPost(tid: Any) {
        PostViewController.doStarPost(tid: tid, callback: { (ok, res) in
            // TODO 收藏逻辑
            print("star result \(ok) \(res)")
        })
    }
    
    
    @objc func newPostClick() {
        if !App.isLogin {
            let alert = UIAlertController(title: "需要登陆", message: "你需要登陆才能发帖", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "登陆", style: .default, handler: { (alert) in
                let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
                self.present(dest!, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "postToNewPostSegue", sender: self)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.title = datas[index.row].title
            dest.tid = datas[index.row].tid
        } else if let dest = segue.destination as? NewPostViewController {
            dest.fid = self.fid
            dest.name = self.title
        } else if let dest = segue.destination as? UserDetailViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            if let uid = datas[index.row].uid {
                dest.uid = uid
                dest.username = datas[index.row].author
            }
        }
    }
    
    // MARK -- 3D touch
    var peekedVc: UIViewController?
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let cell = previewingContext.sourceView as? UITableViewCell, let index = self.tableView?.indexPath(for:cell ) {
            let peekVc = storyboard?.instantiateViewController(withIdentifier: "PostViewController") as! PostViewController
            
            peekVc.title = datas[index.row].title
            peekVc.tid = datas[index.row].tid
            
            peekVc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            self.peekedVc = peekVc
            return peekVc
        }
        
        peekedVc = nil
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = self.peekedVc {
            self.show(vc, sender: self)
        }
    }
}
