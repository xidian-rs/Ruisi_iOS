//
//  HotViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit


class HotViewController: UITableViewController {
    
    let testData  = ["(每人50金币)各位睿思er帮帮忙，花一分钟帮忙填下调查问卷！",
                     "*告诉大家一件事情*",
                     "【5200金币】中兴2018届校招岗位大咖推介会 | 4月19日 19:00 阶教112",
                     "读研有风险，一定要谨慎谨慎再谨慎！"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 85
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        DispatchQueue.main.async {
            if let url = URL(string: HOT_URL){
                if let s = try? String(contentsOf: url , encoding: String.Encoding.utf8){
                    
                    print(s)
                    
                    //let regex = try? NSRegularExpression(pattern: "<[/]?ul.*?>", options: .caseInsensitive)
                    
                    //let neede: String = "<ul class=\"hotlist\">"
                    
                    //let range =  s.range(of: neede)
                    
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let titleLabel = cell.viewWithTag(1) as! UILabel
        //let usernameLabel = cell.viewWithTag(2) as! UILabel
        //let viewsLabel = cell.viewWithTag(3) as! UILabel
        
        titleLabel.text = testData[indexPath.row % 3]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }




    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
