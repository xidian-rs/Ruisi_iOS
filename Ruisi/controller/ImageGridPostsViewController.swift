//
//  ImageGridPostsViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/15.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 图片帖子列表板块
// 摄影天地，等图片板块的controller，注意此页面只在校园网环境下出现
class ImageGridPostsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var fid: Int? // 由前一个页面传过来的值
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var currentPage = 1
    private var totalPage = Int.max
    private var isLoading = false
    private var datas = [ArticleListData]()
    private lazy var rsRefreshControl =  RSRefreshControl()
    private var layout: WaterFallCollectionViewLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        layout = WaterFallCollectionViewLayout()
        layout.delegate = self
        //self.automaticallyAdjustsScrollViewInsets = false //修复collectionView头部空白
        collectionView.collectionViewLayout = layout
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newPostClick))
        
        rsRefreshControl.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 0)
        rsRefreshControl.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        collectionView.addSubview(rsRefreshControl)
        
        rsRefreshControl.beginRefreshing()
        
        loadData()
    }
    
    // 屏幕方向切换
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        if UIDevice.current.orientation.isLandscape {
//            print("Landscape")
//        } else {
//            print("Portrait")
//        }
        layout.updateScreenState(width: Int(size.width))
        self.collectionView.reloadData()
    }
    
    @objc func reloadData() {
        print("下拉刷新'")
        currentPage = 1
        totalPage = Int.max
        loadData()
    }
    
    @objc func newPostClick() {
        if checkLogin(message: "你需要登录才能发帖") {
            self.performSegue(withIdentifier: "imagePostsToNewPost", sender: self)
        }
    }
    
    func loadData() {
        isLoading = true
        HttpUtil.GET(url: Urls.getPostsUrl(fid: fid!) + "&page=\(currentPage)", params: nil) { ok, res in
            //print(res)
            var subDatas: [ArticleListData] = []
            if ok, let doc = try? HTML(html: res, encoding: .utf8) {
                subDatas = self.parseData(doc: doc)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                if subDatas.count > 0 {
                    if self.currentPage == 1 {
                        self.datas = subDatas
                        self.collectionView.reloadData()
                    } else {
                        var indexs = [IndexPath]()
                        for i in 0..<subDatas.count {
                            indexs.append(IndexPath(row: self.datas.count + i, section: 0))
                        }
                        self.datas.append(contentsOf: subDatas)
                        print("here :\(subDatas.count)")
                        self.collectionView.insertItems(at: indexs)
                    }
                } else {
                    //第一次没有加载到数据
                    if self.currentPage == 1 {
                        self.collectionView.reloadData()
                    }
                }
                
                self.rsRefreshControl.endRefreshing(message: ok ? "加载成功": "加载失败")
                self.isLoading = false
            })
        }
    }
    
    func parseData(doc: HTMLDocument) -> [ArticleListData] {
        var subDatas: [ArticleListData] = []
        let nodes = doc.xpath("//*[@id=\"waterfall\"]/li")
        for li in nodes {
            let a = li.xpath("h3/a").first
            var tid: Int?
            if let u = a?["href"] {
                tid = Utils.getNum(from: u)
            } else {
                //没有tid和咸鱼有什么区别
                continue
            }
            
            let title = a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n "))
            var author: String?
            var uid: Int?
            if let authorNode = li.xpath("div[2]/a").first {
                author = authorNode.text!
                uid = Utils.getNum(from: authorNode["href"]!)
            }
            
            let replys = li.xpath("div[2]/cite/a").first?.text
            let views = String(Utils.getNum(from: li.xpath("div[2]/cite").first?.text ?? "0") ?? 0)
            let image = li.xpath("div[1]/a/img").first?["src"]
            
            let d = ArticleListData(title: title ?? "未获取到标题", tid: tid!, author: author ?? "未知作者", replys: replys ?? "0", read: false, haveImage: true, uid: uid, views: views, image: image)
            subDatas.append(d)
        }
        if let pg = doc.xpath("//*[@id=\"fd_page_bottom\"]/div[@class=\"pg\"]").first, let sumNode = pg.xpath("label/span").first {
            self.totalPage = Utils.getNum(from: sumNode.text!) ?? self.currentPage
        } else {
            self.totalPage = self.currentPage
        }
        print("page total:\(self.totalPage)")
        return subDatas
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.layer.cornerRadius = 3.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        cell.layer.shadowRadius = 3.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        let d = datas[indexPath.row]
        let image = cell.viewWithTag(1) as! UIImageView
        let title = cell.viewWithTag(2) as! UILabel
        let author = cell.viewWithTag(3) as! UILabel
        let likes = cell.viewWithTag(4) as! UILabel
        
        if let imageUrl = d.image {
            image.kf.setImage(with: URL(string: Urls.baseUrl + imageUrl), placeholder: #imageLiteral(resourceName:"placeholder"))
        } else {
            image.image = #imageLiteral(resourceName:"placeholder")
        }
        
        title.text = d.title
        author.text = d.author
        likes.text = d.views
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("did select \(indexPath.row)")
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastElement = datas.count - 1
        if !isLoading && indexPath.row == lastElement && currentPage < totalPage {
            if currentPage < totalPage {
                currentPage += 1
            }
            print("load more next page is:\(currentPage) sum is:\(totalPage)")
            loadData()
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController, let cell = sender as? UICollectionViewCell {
            let index = self.collectionView.indexPath(for: cell)!
            dest.title = datas[index.row].title
            dest.tid = datas[index.row].tid
        } else if let dest = segue.destination as? NewPostViewController {
            dest.fid = self.fid
            dest.name = self.title
        }
    }
}

extension ImageGridPostsViewController: WaterFallLayoutDelegate {
    func itemHeightFor(indexPath: IndexPath, itemWidth: CGFloat) -> CGFloat {
        if datas[indexPath.row].image != nil {
            return itemWidth + CGFloat(arc4random_uniform(UInt32(itemWidth))) + 30
        } else {
            return itemWidth
        }
    }
}
