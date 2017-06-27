//
//  PostsViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController {
    
    var fid: Int? // 由前一个页面传过来的值
    var dataCount = 0
    var isLoading = false
    
    @IBOutlet weak var footerIndicate: UIActivityIndicatorView!
    @IBOutlet weak var footerLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 85
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.tableFooterView?.backgroundColor = UIColor(white: 0.95, alpha: 1)
        
        // Initialize the refresh control.
        let refreshControl = UIRefreshControl()
        Widgets.setRefreshControl(refreshControl)
        refreshControl.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    func pullRefresh(){
        print("下拉刷新'")
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 3*NSEC_PER_SEC)) { 
            DispatchQueue.main.async {
                self.dataCount += 3
                if self.tableView.numberOfSections == 0 {
                    self.tableView.reloadData()
                }else{
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [
                        IndexPath(row: self.dataCount-3, section: 0),
                        IndexPath(row: self.dataCount-2, section: 0),
                        IndexPath(row: self.dataCount-1 , section: 0)],
                                              with: .automatic)
                    self.tableView.endUpdates()
                }
                
                if let refreshCtr = self.refreshControl{
                    let df =  DateFormatter()
                    df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                    let str = "Last update: "+df.string(from: Date())
                    
                    let attrStr = NSAttributedString(string: str, attributes: [
                        NSForegroundColorAttributeName:UIColor.white
                        ])
                    
                    refreshCtr.attributedTitle = attrStr
                    refreshCtr.endRefreshing()
                }
            }
        }
        
        
        
    }
    
    //加载更多
    func loadMore(){
        if isLoading {
            return
        }
        isLoading = true
        print("start 加载更多")
        footerIndicate.startAnimating()
        footerLabel.text = "正在加载..."
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(
        deadline: DispatchTime(uptimeNanoseconds: (DispatchTime.now().uptimeNanoseconds + 3*NSEC_PER_SEC))) { [weak self] in
            if let this = self{//加载完毕而且此页面未结束
                print("finish 加载更多")
                this.isLoading = false
                DispatchQueue.main.async {
                    this.footerIndicate.stopAnimating()
                    this.footerLabel.text = "暂无更多"
                    this.dataCount += 3
                    this.tableView.beginUpdates()
                    
                    this.tableView.insertRows(at: [
                        IndexPath(row: this.dataCount - 3, section: 0),
                        IndexPath(row: this.dataCount - 2, section: 0),
                        IndexPath(row: this.dataCount - 1 , section: 0)],
                                               with: .automatic)
                    this.tableView.endUpdates()
                }
            }
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if dataCount == 0 {//no data avaliable
            let label = UILabel(frame:CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = "暂无数据 请下拉刷新"
            label.textColor = UIColor.black
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont(name: "Palatino-Italic", size: 20)
            label.sizeToFit()
            
            tableView.backgroundView = label;
            tableView.separatorStyle = .none;
            tableView.tableFooterView?.isHidden = true
            return 0
        }else{
            tableView.backgroundView = nil
            tableView.tableFooterView?.isHidden = false
            tableView.separatorStyle = .singleLine
            return 1
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataCount
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        return cell
    }
    

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + scrollView.frame.size.height == scrollView.contentSize.height) {
            loadMore()
        }
    }


    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
