//
//  WebViewController.swift
//  Ruisi
//
//  Created by yang on 2018/3/10.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit
import WebKit


class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    private var webView: WKWebView!
    private var progress: UIProgressView!
    
    public var url: URL?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let u = url else {
            showAlert(title: "错误", message: "无法打开链接")
            return
        }
        
        webView = WKWebView(frame: view.bounds)
        
        view.addSubview(webView)
        title = title ?? "网页"
        
        let height =  self.navigationController?.navigationBar.frame.height ?? 0
        progress = UIProgressView(frame: CGRect(x: 0, y: height + 20, width: UIScreen.main.bounds.width, height: 2))
        //设置进度条的高度，下面这句代码表示进度条的宽度变为原来的1倍，高度变为原来的1.5倍.
        progress.transform = CGAffineTransform(scaleX: 1.0, y: 1.5)
        view.addSubview(progress)
    
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        startLoad(url: u)
    }
    
    private func startLoad(url: URL) {
        print("开始加载网页：\(url)")
        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        webView.load(req)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            self.progress.progress = Float(self.webView.estimatedProgress)
            if self.progress.progress == 1 {
                /*
                 *添加一个简单的动画，将progressView的Height变为1.4倍
                 *动画时长0.25s，延时0.3s后开始动画
                 *动画结束后将progressView隐藏
                 */
                UIView.animate(withDuration: 0.25, delay: 0.3, options: .curveEaseOut, animations: { [weak self] in
                    self?.progress.transform = CGAffineTransform(scaleX: 1.0, y: 1.4)
                    }, completion: { [weak self] (finish)  in
                        self?.progress.isHidden = true
                })
            }
        } else if keyPath == "title" {
            self.title = self.webView.title;
        }
        
    }

    //开始加载
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //"开始加载网页"
        self.progress.isHidden = false
        self.progress.transform = CGAffineTransform(scaleX: 1.0, y: 1.5)
        self.view.bringSubview(toFront: self.progress)
    }
    
    //加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progress.isHidden = true
    }
    
    //加载失败
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.progress.isHidden = true
        let alert = UIAlertController(title: "加载失败", message: "加载\(self.url!.absoluteString)失败！你要重新加载吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .default, handler: { (ac) in
            self.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "重新加载", style: .default, handler: { (ac) in
            self.startLoad(url: self.url!)
        }))
        
        self.present(alert, animated: true)
    }

}
