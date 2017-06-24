//
//  LoginViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,UINavigationControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // 判断要显示的控制器是否是自己
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func usernameInputEnd(_ sender: UITextField) {
        print("end",sender.text ?? "")
    }
    
    @IBAction func usernameInputChange(_ sender: UITextField) {
        print("change",sender.text ?? "")
    }
    
    @IBAction func cencelClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func loginClick(_ sender: UIBarButtonItem) {
        print("click")
        //self.dismiss(animated: true, completion: nil)
        var r =  URLRequest(url: URL(string: LOGIN_URL)!)
        print(LOGIN_URL)
        r.httpMethod = "POST"
        r.httpBody = "username=谁用了FREEDOM&password=justice".data(using: .utf8)
        
        //params.put("fastloginfield", "username");
        //params.put("cookietime", "2592000");
        //params.put("questionid", answerSelect + "");
        //if (answerSelect == 0) {
        //    params.put("answer", "");
        //} else {
         //   params.put("answer", edAnswer.getText().toString());
        //}
    
        
        let task = URLSession.shared.dataTask(with: r) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                return
            }
            
            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
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
