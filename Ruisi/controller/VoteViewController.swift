//
//  VoteViewController.swift
//  Ruisi
//
//  Created by yang on 2018/11/28.
//  Copyright © 2018 yang. All rights reserved.
//

import UIKit

class VoteViewController: UITableViewController {
    
    public var voteData: VoteData!
    public var fid: Int!
    public var tid: Int!
    public var callback: ((_ ok: Bool) -> ())?
    
    private var mySelection = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.title = "投票(\(voteData.maxSelect == 1 ? "单选" : "多选"))"
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voteData.options.count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = voteData.options[indexPath.row].value
        
        if mySelection.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if mySelection.contains(indexPath.row) {
            for i in 0..<mySelection.count {
                if mySelection[i] == indexPath.row {
                    mySelection.remove(at: i)
                    break
                }
            }
        } else {
            if mySelection.count >= voteData.maxSelect {
                showAlert(title: "提示", message: "最多选择\(voteData.maxSelect)项")
                return
            } else {
                mySelection.append(indexPath.row)
            }
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    
  
    @IBAction func cancleClick(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
    
    private var progress: UIAlertController?
    @IBAction func doneClick(_ sender: Any) {
        if self.mySelection.count == 0 { return }
        if progress == nil {
            progress = UIAlertController(title: "提交中", message: "请稍后...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 13, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .gray
            loadingIndicator.startAnimating();
            progress!.view.addSubview(loadingIndicator)
            progress!.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        }
        self.present(progress!, animated: true, completion: nil)
        
        var choose = ""
        for item in mySelection {
            if choose == "" {
                choose = voteData.options[item].key
            } else {
                choose = choose + "&pollanswers%5b%5d=" + voteData.options[item].key
            }
            
            if voteData.maxSelect == 1 {
                break
            }
        }
        
        //[] -> %5b%5d
        var url = "forum.php?mod=misc&action=votepoll&fid=\(fid!)&tid=\(tid!)&pollsubmit=yes&quickforward=yes&mobile=2"
        var params = [String:String]()
        if voteData.maxSelect == 1 {
            params["pollanswers[]"] = choose
        } else {
            url = url + "&pollanswers%5b%5d=" + choose
        }
        HttpUtil.POST(url: url, params: params) { (ok, res) in
            print(res)
            var success = false
            var message: String!
            if ok {
                if let err = Utils.getRuisiReqError(res: res) {
                    success = false
                    message = err
                } else {
                    success = true
                    message = "投票成功!"
                }
            } else {
                success = false
                message = "网络不太通畅,请稍后重试"
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.progress?.dismiss(animated: true) {
                    let alert = UIAlertController(title: success ? "投票成功!" : "错误", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: success ? "取消" : "好", style: .cancel, handler: nil))
                    if success {
                        alert.addAction(UIAlertAction(title: "关闭", style: .default) { action in
                            self?.dismiss(animated: true, completion: {
                                self?.callback?(true)
                                self?.presentingViewController?.dismiss(animated: true)
                            })
                        })
                    }
                    
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
