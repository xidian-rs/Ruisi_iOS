//
//  HotViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 首页 - 热帖/新帖
class HotViewController: BaseTableViewController<ArticleListData> {
    
    override func viewDidLoad() {
        self.autoRowHeight = false
        self.showRefreshControl = true
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    // 切换热帖0 和 新帖1
    @IBAction func viewTypeChnage(_ sender: UISegmentedControl) {
        position = sender.selectedSegmentIndex
        self.isLoading = false
        self.datas = []
        self.tableView.reloadData()
        self.rsRefreshControl?.beginRefreshing()
        reloadData()
    }
    
    var isHotLoading = false
    var isNewLoading = false
    override var isLoading: Bool {
        get {
            if position == 0 {
                return isHotLoading
            } else {
                return isNewLoading
            }
        }
        
        set {
            if position == 0 {
                isHotLoading = newValue
            } else {
                isNewLoading = newValue
            }
            super.isLoading = newValue
        }
    }
    
    
    override func getUrl(page: Int) -> String {
        if position == 0 {
            return Urls.hotUrl + "&page=\(currentPage)"
        } else {
            return Urls.newUrl + "&page=\(currentPage)"
        }
    }
    
    override func parseData(pos: Int, doc: HTMLDocument) -> [ArticleListData] {
        currentPage = Int(doc.xpath("/html/body/div[2]/strong").first?.text ?? "") ?? currentPage
        totalPage = Utils.getNum(from: (doc.xpath("/html/body/div[2]/label/span").first?.text) ?? "") ?? currentPage
        var subDatas: [ArticleListData] = []
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
        return subDatas
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let usernameLabel = cell.viewWithTag(2) as! UILabel
        let commentsLabel = cell.viewWithTag(3) as! UILabel
        let haveImageLabel = cell.viewWithTag(4) as! UILabel
        let d = datas[indexPath.row]
        
        titleLabel.text = d.title
        if let color = d.titleColor {
            titleLabel.textColor = color
        }
        usernameLabel.text = d.author
        commentsLabel.text = d.replyCount
        haveImageLabel.isHidden = !d.haveImage
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = datas[indexPath.row]
        return d.rowHeight
    }
    
    // 计算行高
    private func caculateRowheight(isSchoolNet: Bool, width: CGFloat, title: String) -> CGFloat {
        let titleHeight = title.height(for: width - 30, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        // 上间距(12) + 正文(计算) + 间距(8) + 昵称(14.5) + 下间距(10)
        return 12 + titleHeight + 8 + 14.5 + 10
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.title = datas[index.row].title
            dest.tid = datas[index.row].tid
        }
    }
}
