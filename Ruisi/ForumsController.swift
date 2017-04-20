//
//  ForumsController.swift
//  Ruisi
//
//  Created by yang on 2017/4/17.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class ForumsController: UICollectionViewController,UICollectionViewDelegateFlowLayout{

    var datas:[Forums] = []
    let logoDir = "assets/forumlogo/"
    let jsonPath = "assets/forums"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        
        //load json data
        let filePath = Bundle.main.path(forResource: "assets/forums", ofType: "json")!
        
        if let d = try? Data(contentsOf: URL(fileURLWithPath: filePath, isDirectory: false)){
                let json = try? JSONSerialization.jsonObject(with: d, options: [])
                
                if let jarray =  json as? [Any]{
                    
                    for case let jo as [String:Any] in jarray{
                        let  forumGroup  = Forums(gid: jo["gid"] as! Int,
                                                  name: jo["name"] as! String,
                                                  login: jo["login"] as! Bool)
                        
                        print("gid = \(jo["gid"] as! Int), name = \(jo["name"] as! String)")
                        
                        let fs = jo["forums"] as! [Any]
                        
                        
                        var forums:[Forums.Forum] = []
                        for case let  f as [String:Any] in fs{
                            let forum = Forums.Forum(fid: f["fid"] as! Int,
                                                     name: f["name"] as! String,
                                                     login: f["login"] as! Bool)
                            print("\tfid = \(f["fid"] as! Int), name = \(f["name"] as! String)")
                            forums.append(forum)
                        }
                        
                        forumGroup.setForums(forums: forums)
                        datas.append(forumGroup)
                    }
                }
          }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        print("select")
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPosts"{//版块帖子列表
            if let dest = (segue.destination as? PostsViewController) {
                
                if let index = collectionView?.indexPathsForSelectedItems?[0]{
                    dest.title = datas[index.section].forums?[index.row].name
                }
            }
        }
    }


    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
