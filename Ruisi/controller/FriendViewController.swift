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
class FriendViewController: BaseTableViewController<FriendData>,UISearchBarDelegate {
    private var datasCopy:[FriendData] = []
    private var searchMode = false
    private var isInSearchMode: Bool {
        set {
            if newValue != searchMode {
                searchMode = newValue
                if searchMode { //enterSearchMode
                    showFooter = false
                    datasCopy = datas
                    emptyPlaceholderText = "没有搜索到结果,点击确认搜索全站用户"
                } else { //exit searchMode
                    datas = datasCopy
                    showFooter = true
                    emptyPlaceholderText = "加载中..."
                }
                tableView.reloadData()
            }
        }
        get {
            return searchMode
        }
    }
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        self.autoRowHeight = false
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        isInSearchMode = false
        searchBar.delegate = self
    }
    
    
    override func getUrl(page: Int) -> String {
        return Urls.friendsUrl + "&page=\(page)"
    }
    
    
    override func parseData(pos:Int, doc: HTMLDocument) -> [FriendData]{
        var subDatas:[FriendData] = []
        //print(doc.body?.text)
        let nodes: XPathObject
        if isInSearchMode {
            nodes = doc.xpath("//*[@id=\"ct\"]/div[1]/div/ul[2]/li")
        }else {
            nodes = doc.xpath("//*[@id=\"friend_ul\"]/ul/li")
        }
        
        for li in nodes {
            if let n = li.xpath("h4/a").first {
                let uname = n.text
                let unameColor =  Utils.getHtmlColor(from: n["style"])
                let uid = Utils.getNum(from: n["href"]!)
                let description = li.xpath("p").first?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let isOnline = li.xpath("em").first?["title"] != nil
                let isFriend: Bool
                if isInSearchMode {
                    isFriend = !li.text!.contains("加为好友")
                }else {
                    isFriend = true
                }
                
                let d = FriendData(uid: uid!, username: uname ?? "未获取用户名", description: description, usernameColor: unameColor, online: isOnline,isFriend: isFriend)
                subDatas.append(d)
            }
        }
        if !isInSearchMode && subDatas.count == 0 {
            self.totalPage = self.currentPage
        }
        print("finish load data pos:\(pos) count:\(subDatas.count)")
        return subDatas
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let avatarView = cell.viewWithTag(1) as! UIImageView
        let usernameView = cell.viewWithTag(2) as! UILabel
        let descriptionView = cell.viewWithTag(3) as! UILabel
        let addBtn = cell.viewWithTag(4) as! UIButton
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick(_:))))
        avatarView.kf.setImage(with: Urls.getAvaterUrl(uid: datas[indexPath.row].uid), placeholder: #imageLiteral(resourceName: "placeholder"))
        usernameView.text = datas[indexPath.row].username
        if let color = datas[indexPath.row].usernameColor {
            usernameView.textColor = color
        }else {
            usernameView.textColor = UIColor.darkText
        }
        descriptionView.text = datas[indexPath.row].description
        
        addBtn.isHidden = datas[indexPath.row].isFriend
        if !addBtn.isHidden {
            addBtn.addTarget(self, action: #selector(addFriendClick), for: .touchUpInside)
        }
        
        return cell
    }
    
    
    @objc func addFriendClick(_ sender: UIButton!){
        if let cell  =  sender.superview?.superview as? UITableViewCell,let index = tableView.indexPath(for: cell) {
            let user = datas[index.row]
            let alert = UIAlertController(title: "添加好友", message: "你要添加好友【\(user.username)】?吗?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "添加", style: .default, handler: { (action) in
                print("添加好友\(user.username) uid:\(user.uid)")
                self.doAddFriend(indexPath: index, uid: user.uid)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
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
        HttpUtil.POST(url: Urls.deleteFriendUrl(uid: uid), params: ["friendsubmit":"true"]) { (ok, res) in
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
    
    func doAddFriend(indexPath:IndexPath, uid:Int) {
        HttpUtil.POST(url: Urls.addFriendUrl(uid: uid), params: ["addsubmit":"true","handlekey":"friend_\(uid)","note":"","gid":1,"addsubmit_btn":"true"]) { (ok, res) in
            var title: String
            var message: String
            if ok {
                title = "提示"
                if res.contains("好友请求已") {
                    message =  "请求已发送成功，正在请等待对方验证"
                } else if res.contains("正在等待验证") {
                    message = "好友请求已经发送了，正在等待对方验证"
                } else if res.contains("你们已成为好友") {
                    message = "你们已经是好友了不用添加了..."
                } else {
                    message = "未知结果..."
                }
            } else {
                title = "操作失败"
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    message = doc.xpath("//html/body/div[1]/p[1]").first?.text ?? ""
                }else {
                    message = "未知错误..."
                }
            }
            
            DispatchQueue.main.async {
                let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil ))
                self.present(vc, animated: true)
            }
        }
    }
    
    @objc func avatarClick(_ sender : UITapGestureRecognizer)  {
        if  let index = tableView.indexPath(for: sender.view?.superview?.superview as! UITableViewCell ) {
            self.performSegue(withIdentifier: "friendToUserDetail", sender: index)
        }
    }
    
    
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("text change:\(searchText)")
        let text = searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        if text.count == 0 {
            isInSearchMode = false
        }else {
            isInSearchMode = true
            datas  = datas.filter({$0.username.lowercased().contains(text)})
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search click")
        isInSearchMode = true
        if let text = searchBar.text,text.count > 0 {
            searchBar.resignFirstResponder()
            doSearch(text: text.trimmingCharacters(in: CharacterSet.whitespaces))
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel click")
        isInSearchMode = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func doSearch(text:String) {
        let label = tableView.backgroundView as? UILabel
        label?.text = "搜索中..."
        
        HttpUtil.GET(url: Urls.searchFriendUrl(username: text), params: nil) { (ok, res) in
            if ok,let doc = try? HTML(html: res, encoding: .utf8) {
                let ds = self.parseData(pos: 0, doc: doc)
                DispatchQueue.main.async {
                    if ds.count > 0 {
                        //搜索到结果
                        self.datas = ds
                        self.tableView.reloadData()
                    }else {
                        self.emptyPlaceholderText = "没有搜索到结果:\(text)"
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? ChatViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.uid = datas[index.row].uid
            dest.username = datas[index.row].username
        }else if let dest = segue.destination as? UserDetailViewController,
            let index = sender as? IndexPath {
            dest.uid = datas[index.row].uid
            dest.username = datas[index.row].username
            dest.isFriend = datas[index.row].isFriend
        }
    }
    
}
