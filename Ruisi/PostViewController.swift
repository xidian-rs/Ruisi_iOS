//
//  PostViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/20.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 帖子详情页
class PostViewController: UITableViewController,UITextViewDelegate {
    
    var tid: Int? // 由前一个页面传过来的值
    private var loading = false
    var datas =  [PostData]()
    var contentTitle: String?
    var currentPage = 1
    var pageSum: Int = 1
    
    
    var url :String {
        return Urls.getPostUrl(tid: tid!) + "&page=\(currentPage)"
    }
    
    var isLoading: Bool{
        get{
            return loading
        }
        set {
            loading = newValue
            if !loading {
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView =
            LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action , target: self, action: #selector(PostViewController.showMoreView)),
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(PostViewController.refreshData))
        ]
        
        if tid == nil {
            showBackAlert(message: "没有传入tid参数")
            return
        }
        
        loadData()
    }
    
    
    //刷新数据
    func refreshData() {
        print("refresh click")
    }
    
    //显示跟多按钮
    func showMoreView(){
        let sheet = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "浏览器中打开", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: "http://www.baidu.com")! ,
                                      options: [:],
                                      completionHandler: nil)
            
        }))
        
        sheet.addAction(UIAlertAction(title: "收藏文章", style: .default, handler: { (UIAlertAction) in
            print("star click")
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
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {
            return 0
        }
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else {
            return datas.count - 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data: PostData
        let cell: UITableViewCell
        if indexPath.section == 0 {
            data = datas[0]
            cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath)
            let title = cell.viewWithTag(6) as! UILabel
            title.text = contentTitle ?? self.title
        } else {
            data = datas[indexPath.row + 1]
            cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath)
            let index = cell.viewWithTag(6) as! UILabel
            index.text = data.index
        }
        
        let img = cell.viewWithTag(1) as! UIImageView
        let author = cell.viewWithTag(2) as! UILabel
        let lz = cell.viewWithTag(3) as! UILabel
        let time = cell.viewWithTag(4) as! UILabel
        let content = cell.viewWithTag(5) as! UITextView
        
        author.text = data.author
        time.text = "发表于:\(data.time)"
        
        content.delegate = self
        content.isEditable = false
        content.isScrollEnabled  = false
        content.attributedText = AtrributeConveter().convert(src: data.content)
        return cell
    }
    
    func loadData(_ pos: Int = 0) {
        // 所持请求的数据正在加载中/未加载
        if isLoading {
            return
        }
        isLoading = true
        print("load data page \(currentPage)")
        
        
        HttpUtil.GET(url: url, params: nil) { ok, res in
            var subDatas = [PostData]()
            if ok ,let doc = HTML(html: res, encoding: .utf8) {
                if self.contentTitle == nil, let t = doc.title {
                    self.contentTitle = t.substring(to: t.index(of: " - ")!)
                }
                
                let comments = doc.css(".postlist .plc.cl")
                if comments.count > 0 {
                    //获得回复楼主的url
                    var replyUrl: String?
                    if self.datas.count == 0 {
                        replyUrl = doc.css("form#fastpostform").first?["action"]
                    }
                    
                    //获取总页数 和当前页数
                    if let pg =  doc.css(".pg").first {
                        // var page = Utils.getNum(from: pg.css("strong").first?.text ?? "1")
                        let sum = Utils.getNum(from: pg.css("span").first?["title"] ?? "1")
                        if let s = sum , sum! > 1 {
                            self.pageSum = s
                        }
                    }
                    
                    //解析评论列表
                    for comment in comments {
                        var pid: String?
                        if let spid = comment["id"] {
                            pid = spid.substring(from: spid.range(of: "pid")!.upperBound)
                        } else {
                            // pid 都没有和咸鱼有什么区别
                            continue
                        }
                        
                        var author: String?
                        var uid: String?
                        var index: String?
                        let infoNode = comment.css("ul.authi")
                        if let sinfo = infoNode.first?.css("li").first {
                            author = (sinfo.css("a").first?.text)!
                            uid = String(Utils.getNum(from: (sinfo.css("a").first?["href"])!) ?? 0)
                            index = sinfo.css("em").first?.text
                        }
                        
                        var time: String?
                        if let stime = infoNode.first?.css(".rela").first {
                            time = stime.text?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "收藏", with: "")
                        }
                        
                        //层主url
                        if self.datas.count > 0 || subDatas.count > 0 {
                            replyUrl = comment.css(".replybtn input").first?["href"]
                        }
                        
                        let content = comment.css(".message").first?.innerHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    return
                }
            } else {
                print("加载失败 网络错误")
            }
            
            //load data ok
            // 第一次换页清空
            if self.currentPage == 1 {
                self.datas = subDatas
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                let count = self.datas.count
                self.datas.append(contentsOf: subDatas)
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    var indexs = [IndexPath]()
                    for i in 0 ..< subDatas.count {
                        indexs.append(IndexPath(row: count + i, section: 0))
                    }
                    self.tableView.insertRows(at: indexs, with: .automatic)
                    self.tableView.endUpdates()
                }
            }
            
            if self.currentPage < self.pageSum {
                self.currentPage += 1
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 1 * NSEC_PER_SEC)){
                self.isLoading = false
            }
            print("finish http")
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
