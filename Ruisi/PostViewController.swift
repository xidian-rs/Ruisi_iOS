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
class PostViewController: AbstractTableViewController<PostData>,UITextViewDelegate {
    
    var tid: Int? // 由前一个页面传过来的值
    var saveToHistory = false //是否保存到历史记录
    var contentTitle: String?
    var pageSum: Int = 1
    
    override func getUrl(page: Int) -> String {
        if self.currentPage > self.pageSum {
            self.currentPage = self.pageSum
            return Urls.getPostUrl(tid: tid!) + "&page=\(pageSum)"
        } else {
            return Urls.getPostUrl(tid: tid!) + "&page=\(page)"
        }
    }
    
    override func viewDidLoad() {
        if tid == nil {
            showBackAlert(message: "没有传入tid参数")
            return
        }
        
        super.viewDidLoad()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action , target: self, action: #selector(PostViewController.showMoreView)),
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(PostViewController.refreshData))
        ]
    }
    
    
    //刷新数据
    @objc func refreshData() {
        print("refresh click")
    }
    
    //显示更多按钮
    @objc func showMoreView(){
        let sheet = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "浏览器中打开", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: self.getUrl(page: self.currentPage))! ,
                                      options: [:], completionHandler: nil)
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        }
        
        let img = cell.viewWithTag(1) as! UIImageView
        let author = cell.viewWithTag(2) as! UILabel
        let lz = cell.viewWithTag(3) as! UILabel
        let time = cell.viewWithTag(4) as! UILabel
        let content = cell.viewWithTag(5) as! UITextView
        
        lz.isHidden = datas[0].author != data.author
        
        author.text = data.author
        time.text = "发表于:\(data.time)"
        img.kf.setImage(with:  Urls.getAvaterUrl(uid: data.uid))
        content.delegate = self
        content.isEditable = false
        content.isScrollEnabled  = false
        content.attributedText = AtrributeConveter().convert(src: data.content)
        return cell
    }
    
    // 子类重写此方法支持解析自己的数据
    override func parseData(pos:Int, doc: HTMLDocument) -> [PostData]{
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
            
            //解析评论列表
            for comment in comments {
                var pid: String?
                if let spid = comment["id"]  { //pid23224562
                    pid = String(spid [spid.range(of: "pid")!.upperBound...])
                } else {
                    // pid 都没有和咸鱼有什么区别
                    continue
                }
                
                if datas.count > 0 {
                    //过滤重复的
                    for i in (0 ..< datas.count).reversed() {
                        if datas[i].pid == pid {
                            return subDatas
                        }
                    }
                }
                
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
    

    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
