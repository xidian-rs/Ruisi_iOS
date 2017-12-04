//
//  ForumsController.swift
//  Ruisi
//
//  Created by yang on 2017/4/17.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit


// didload -> willappear
class ForumsViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout{
    let reuseIdentifier = "Cell"
    var datas:[Forums] = []
    let logoDir = "assets/forumlogo/"
    let jsonPath = "assets/forums"
    var loginState: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if App.isLogin != loginState { //第一次
            loginState = App.isLogin
            loadData(loginState: loginState)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        loginState = App.isLogin
        loadData(loginState: loginState)
    }

    func loadData(loginState: Bool) {
        print("load forums login state:\(loginState)")
        let filePath = Bundle.main.path(forResource: "assets/forums", ofType: "json")!
        //let jsonData = jsonString.data(encoding: .utf8)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath, isDirectory: false))
        let decoder = JSONDecoder()
        datas = try! decoder.decode([Forums].self, from: data).filter({ (f) -> Bool in
            f.forums = f.forums?.filter({ (ff) -> Bool in
                return loginState || !ff.login
            })
            return loginState || !f.login
        })
        
        collectionView?.reloadData()
    }

    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return datas.count
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    //单元格大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = (collectionView.frame.width - 90)/4.0
        return CGSize(width: cellSize, height: cellSize+16)
    }
    
    // collectionView的上下左右间距    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
    }
    
    
    // 单元的行间距    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    
    // 每个小单元的列间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    
    // section 头或者尾部
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader{
            let head = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "head", for: indexPath)
            let label = head.viewWithTag(1) as! UILabel
            label.text = datas[indexPath.section].name
            head.backgroundColor = UIColor(white: 0.95, alpha: 1)
            return head
        }
        
        return UICollectionReusableView(frame: CGRect.zero)
    }
    
    

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas[section].getSize()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        let label = cell.viewWithTag(2) as! UILabel
        let fileName = datas[indexPath.section].forums![indexPath.row].fid
        let path = Bundle.main.path(forResource: "common_\(fileName)_icon", ofType: "gif", inDirectory: logoDir)!
        imageView.image = UIImage(contentsOfFile: path)
        label.text = datas[indexPath.section].forums![indexPath.row].name
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("select")
    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPosts"{//版块帖子列表
            if let dest = (segue.destination as? PostsViewController) {
                if let index = collectionView?.indexPathsForSelectedItems?[0]{
                    dest.title = datas[index.section].forums?[index.row].name
                    dest.fid = datas[index.section].forums?[index.row].fid
                }
            }
        }
    }

}
