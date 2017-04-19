//
//  MyViewTableController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class MyViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var myTableView: UITableView!
    
    var images = ["ic_refresh_48pt","ic_info_48pt","ic_share_48pt","ic_favorite_48pt","ic_settings_48pt"]
    var titles = ["签到中心","关于本程序","分享手机睿思","到商店评分","设置"]

    override func viewDidLoad() {
        super.viewDidLoad()

        myTableView.dataSource = self
        myTableView.delegate = self
        
        myTableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    

   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let imageview  = cell.viewWithTag(1) as! UIImageView
        let label = cell.viewWithTag(2) as! UILabel
        
        
        imageview.image = UIImage(named: images[indexPath.row])
        
        label.text = titles[indexPath.row]

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }



    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
