//
//  FriendViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 我的好友页面
class FriendViewController: AbstractTableViewController<FriendData> {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func getUrl(page: Int) -> String {
        return Urls.friendsUrl + "&page=\(page)"
    }

    
    override func parseData(pos:Int, doc: HTMLDocument) -> [FriendData]{
        var subDatas:[FriendData] = []
        //print(doc.body?.text)
        let nodes = doc.xpath("//*[@id=\"friend_ul\"]/ul/li")
        for li in nodes {
            if let n = li.xpath("h4/a").first {
                let uname = n.text
                let unameColor =  Utils.getHtmlColor(from: n["style"])
                let uid = Utils.getNum(from: n["href"]!)
                let description = li.xpath("p").first?.text
                let isOnline = li.xpath("em").first?["title"] != nil
                
                let d = FriendData(uid: uid!, username: uname ?? "未获取用户名", description: description, usernameColor: unameColor, online: isOnline)
                subDatas.append(d)
            }
        }
        
        print("finish load data pos:\(pos) count:\(subDatas.count)")
        return subDatas
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let avatarView = cell.viewWithTag(1) as! UIImageView
        let usernameView = cell.viewWithTag(2) as! UILabel
        let descriptionView = cell.viewWithTag(3) as! UILabel
        
        avatarView.kf.setImage(with: Urls.getAvaterUrl(uid: datas[indexPath.row].uid), placeholder: #imageLiteral(resourceName: "placeholder"))
        usernameView.text = datas[indexPath.row].username
        if let color = datas[indexPath.row].usernameColor {
            usernameView.textColor = color
        }
        descriptionView.text = datas[indexPath.row].description
        
        return cell
    }


    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            showDeleteFriendAlert(indexPath: indexPath)
            //tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func showDeleteFriendAlert(indexPath: IndexPath) {
        let username = datas[indexPath.row].username
        let uid =  datas[indexPath.row].uid
        let alert = UIAlertController(title: "删除好友", message: "你要删除好友【\(username)】?吗?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { (action) in
            print("删除好友\(username) uid:\(uid)")
            self.doDeleteFriend(indexPath: indexPath, uid: uid)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func doDeleteFriend(indexPath:IndexPath, uid:Int) {
        let params = "friendsubmit=true"
        HttpUtil.POST(url: Urls.deleteFriendUrl(uid: uid), params: params) { (ok, res) in
            print("post ok")
            if ok && res.contains("操作成功"){
                DispatchQueue.main.async { [weak self] in
                    self?.datas.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            } else {
                // TODO 失败
                DispatchQueue.main.async { [weak self] in
                    ///html/body/div[1]/p[1]
                    var reason:String?
                    if let doc = try? HTML(html: res, encoding: .utf8) {
                        reason = doc.xpath("//html/body/div[1]/p[1]").first?.text
                    }
                    let vc = UIAlertController(title: "操作失败", message: "删除好友失败:\(reason ?? res)", preferredStyle: .alert)
                    vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil ))
                    self?.present(vc, animated: true)
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UserDetailViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.uid = datas[index.row].uid
            dest.username = datas[index.row].username
        }
    }

}
