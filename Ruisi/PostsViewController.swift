//
//  PostsViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

class PostsViewController: AbstractTableViewController<ArticleListData> {
    
    var fid: Int? // 由前一个页面传过来的值
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func getUrl(page: Int) -> String {
        return Urls.getPostsUrl(fid: fid!) + "&page=\(page)"
    }
    
    // 子类重写此方法支持解析自己的数据
    override func parseData(pos:Int, doc: HTMLDocument) -> [ArticleListData]{
        var subDatas:[ArticleListData] = []
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
            let d = ArticleListData(title: title ?? "未获取到标题", tid: tid!, author: authorStr ?? "未知作者",replys: replysStr ?? "0", read: false, haveImage: haveImg, titleColor: color)
            subDatas.append(d)
        }
        
        print("finish load data pos:\(pos) count:\(subDatas.count)")
        return subDatas
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let usernameLabel = cell.viewWithTag(2) as! UILabel
        let commentsLabel = cell.viewWithTag(3) as! UILabel
        let d = datas[indexPath.row]
        
        titleLabel.text = d.title
        if let color = d.titleColor {
            titleLabel.textColor = color
        }
        usernameLabel.text = d.author
        commentsLabel.text = d.replyCount
        
        return cell
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
