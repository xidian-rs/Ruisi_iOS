//
//  ForumsController.swift
//  Ruisi
//
//  Created by yang on 2017/4/17.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 首页 - 板块列表
class ForumsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private var datas: [Forums] = []
    var loadedUid: Int?
    private var colCount = 6 //collectionView列数
    private var type = 1 // 0-grid显示 1-列表显示
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadedUid = Settings.uid
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.clearsSelectionOnViewWillAppear = true
        type = Settings.forumListDisplayType ?? 1
        caculateColCount()
        loadData(uid: loadedUid)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Settings.uid != loadedUid { //第一次
            loadedUid = Settings.uid
            loadData(uid: loadedUid)
        }
    }
    
    @IBAction func switchDisplayTypeClick(_ sender: UIBarButtonItem) {
        if type == 0 {
            type = 1
        } else {
            type = 0
        }
        
        Settings.forumListDisplayType = type
        caculateColCount()
        self.collectionView?.reloadData()
    }
    
    private func caculateColCount() {
        if type == 0 {
            colCount = Int(UIScreen.main.bounds.width / 80)
        } else {
            colCount = Int(UIScreen.main.bounds.width / 135)
        }
    }
    
    // uid == nil 加载未登陆的
    func loadData(uid: Int?) {
        print("====================")
        print("加载板块列表")
        
        let day = Int(Date().timeIntervalSince1970 / 86400) - Settings.getFormlistSavedTime(uid: uid)
        if day >= 7 {
            print("缓存过期\(day)，从网页读取板块列表")
            loadFormlistFromWeb()
            return
        } else if let d = Settings.getForumlist(uid: uid),let ds = try? JSONDecoder().decode([Forums].self, from: d) {
            //不用过滤
            datas = ds
            print("从保存的设置里面 读取板块列表 uid:\(uid ?? 0)")
        }
        
        if datas.count == 0 {
            print("临时使用forums.json板块列表")
            let filePath = Bundle.main.path(forResource: "assets/forums", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: filePath, isDirectory: false))
            datas = try! JSONDecoder().decode([Forums].self, from: data).filter({ (f) -> Bool in
                f.forums = f.forums?.filter({ (ff) -> Bool in
                    return (loadedUid != nil) || !ff.login
                })
                return (loadedUid != nil) || !f.login
            })
            collectionView?.reloadData()
            
            print("开始从网页读取板块列表")
            loadFormlistFromWeb()
        }
    }
    
    private func loadFormlistFromWeb() {
        HttpUtil.GET(url: Urls.forumlistUrl, params: nil) { [weak self] (ok, res) in
            guard ok else { return }
            if let html = try? HTML(html: res, encoding: .utf8) {
                var uid: Int?
                if let userNode = html.xpath("//*[@id=\"usermsg\"]/a").first {
                    uid = Utils.getNum(prefix: "uid=", from: userNode["href"]!)
                }
                let groups = html.xpath("//*[@id=\"wp\"]/div")
                var listForms = [Forums]()
                for group in groups {
                    if let groupName = group.xpath(".//h2/a").first?.text {
                        let items = group.xpath(".//a")
                        var forms = [Forums.Forum]()
                        for item in items {
                            if let fid = Utils.getNum(prefix: "fid=", from: item["href"]!) {
                                var new: Int?
                                if let numNode = item.xpath("span").first {
                                    new = Utils.getNum(from: numNode.text!)
                                    item.removeChild(numNode)
                                }
                                
                                let f = Forums.Forum(fid: fid, name: item.text!, login: false)
                                f.new = new
                                
                                forms.append(f)
                            }
                        }
                        
                        let formss = Forums(gid: 0, name: groupName, login: false, canPost: true)
                        formss.forums = forms
                        
                        listForms.append(formss)
                    }
                }
                
                self?.datas = listForms
                self?.loadedUid = uid
                
                DispatchQueue.main.async {
                    self?.collectionView?.reloadData()
                }
                
                print("从网页加载板块列表完成 登陆:\(App.isLogin) uid:\(uid ?? 0) 设置里的uid:\(Settings.uid ?? 0)")
                if let d = try? JSONEncoder().encode(listForms) {
                    Settings.setForumlist(uid: uid, data: d)
                    print("板块列表保存完毕")
                }
            }
        }
    }
    
    // 点击头像
    @objc func tapHandler(sender: UITapGestureRecognizer) {
        if App.isLogin {
            self.performSegue(withIdentifier: "myProvileSegue", sender: nil)
        } else {
            //login
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
            self.present(dest!, animated: true, completion: nil)
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return datas.count
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    //单元格大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if type == 0 {
            let cellSize = (collectionView.frame.width - CGFloat((colCount - 1) * 5) - CGFloat(16)) / CGFloat(colCount)
            return CGSize(width: cellSize, height: cellSize + UIFont.systemFont(ofSize: 12).lineHeight - 6)
        } else {
            let cellSize = (collectionView.frame.width - CGFloat(16)) / CGFloat(colCount)
            return CGSize(width: cellSize, height: 52)
        }
    }
    
    // collectionView的上下左右间距    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    }
    
    
    // 单元的行间距    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return (type == 0) ? 5 : 0
    }
    
    
    // 每个小单元的列间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return (type == 0) ? 5 : 0
    }
    
    // 是否能变色
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // 变色
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
    }
    
    //结束变色
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor.clear
    }
    
    // 修复头部在滚动条下面
    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        view.layer.zPosition = 0.0
    }
    
    // section 头或者尾部
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let head = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "head", for: indexPath)
            let label = head.viewWithTag(1) as! UILabel
            label.text = datas[indexPath.section].name
            label.textColor = ThemeManager.currentPrimaryColor
            head.backgroundColor = UIColor(white: 0.96, alpha: 1)
            return head
        }
        
        return UICollectionReusableView(frame: CGRect.zero)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas[section].getSize()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: (type == 0) ? "grid_cell" : "list_cell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        let label = cell.viewWithTag(2) as! UILabel
        let countLabel = cell.viewWithTag(3) as? UILabel
        let fid = datas[indexPath.section].forums![indexPath.row].fid
        if let path = Bundle.main.path(forResource: "common_\(fid)_icon", ofType: "gif", inDirectory: "assets/forumlogo/") {
            imageView.image = UIImage(contentsOfFile: path)
        } else {
            let r = URL(string: "\(Urls.baseUrl)data/attachment/common/cc/common_\(fid)_icon.gif?mobile=2")
            imageView.kf.setImage(with:  r, placeholder: #imageLiteral(resourceName: "placeholder"))
        }
        
        label.text = datas[indexPath.section].forums![indexPath.row].name
        countLabel?.textColor = ThemeManager.currentPrimaryColor
        if let count = datas[indexPath.section].forums![indexPath.row].new, count > 0 {
            countLabel?.text = "+\(count)"
        } else {
            countLabel?.text = ""
        }
        return cell
    }
    
    var selectedIndexPath: IndexPath?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let type = Urls.getPostsType(fid: datas[indexPath.section].forums![indexPath.row].fid, isSchoolNet: App.isSchoolNet)
        switch type {
        case .imageGrid:
            self.performSegue(withIdentifier: "forumToImagePosts", sender: self)
        default:
            self.performSegue(withIdentifier: "forumToNormalPosts", sender: self)
        }
    }
    
    
    // MARK: UICollectionViewDelegate
    func showLoginAlert() {
        let alert = UIAlertController(title: "需要登陆", message: "你需要登陆才能执行此操作", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "登陆", style: .default, handler: { (alert) in
            let dest = self.storyboard?.instantiateViewController(withIdentifier: "loginViewNavigtion")
            self.present(dest!, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "formToSearchSegue" {
            if !App.isLogin {
                showLoginAlert()
                return false
            }
        }
        return true
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let index = selectedIndexPath {
            let fid = datas[index.section].forums?[index.row].fid
            let title = datas[index.section].forums?[index.row].name
            
            if let dest = (segue.destination as? PostsViewController) {
                dest.title = title
                dest.fid = fid
            } else if let dest = (segue.destination as? ImageGridPostsViewController) {
                dest.title = title
                dest.fid = fid
            }
        }
    }
    
}
