//
//  HistoryViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import CoreData

class HistoryViewController: UITableViewController {

    var historys:[History] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(delBtnClick))
        
        //load data from coredata
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "History")
        fetchRequest.fetchLimit = 100
        fetchRequest.fetchOffset = 0
        
        // 排序 ascendingYes为递增排序，ascending为No递减排序
        let sort = NSSortDescriptor.init(key: "time", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
//        let predicate = NSPredicate.init(format: "name = 'nnn'", "")
//        fetchRequest.predicate = predicate
        
        do {
            if let fetchedObjects = try context.fetch(fetchRequest) as? [History] {
                print("history size is \(fetchedObjects.count)")
                historys = fetchedObjects
                tableView.reloadData()
            }
        } catch  {
            let nserror = error as NSError
            showBackAlert(message: nserror.localizedDescription)
        }
    }
    
    private func showBackAlert(message: String) {
        let alert = UIAlertController(title: "无法加载历史记录", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "关闭", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    @objc func delBtnClick() {
        let alert = UIAlertController(title: "清空浏览历史", message: "你要清空你的浏览记录吗?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "清空", style: .destructive, handler: { (action) in
            print("清空浏览历史")
            let app = UIApplication.shared.delegate as! AppDelegate
            let contexts = app.persistentContainer.viewContext
            let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "History")
            let deleteRequest:NSBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? contexts.execute(deleteRequest)
            app.saveContext()
            
            self.historys = []
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleView = cell.viewWithTag(1) as! UILabel
        let authorView = cell.viewWithTag(2) as! UILabel
        let timeView = cell.viewWithTag(3) as! UILabel
        
        titleView.text = historys[indexPath.row].title
        authorView.text = historys[indexPath.row].author
        timeView.text = historys[indexPath.row].created
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tid = historys[indexPath.row].tid
            let app = UIApplication.shared.delegate as! AppDelegate
            let contexts = app.persistentContainer.viewContext
            
            let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.fetchOffset = 0
            
            let entity = NSEntityDescription.entity(forEntityName: "History", in: contexts)
            fetchRequest.entity = entity
            
            let predicate = NSPredicate.init(format: "tid = '\(tid)'", "")
            fetchRequest.predicate = predicate
            
            //var delete = false
            let fetchedObjects = try? contexts.fetch(fetchRequest) as? [History]
            if let results = fetchedObjects {
                for one: History in results! {
                    print("delete history \(one.tid)")
                    contexts.delete(one)
                    //delete = true
                    app.saveContext()
                }
            }
            
            historys.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.title = historys[index.row].title
            dest.tid = Int(historys[index.row].tid)
            dest.saveToHistory = true
        }
    }
}
