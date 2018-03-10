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
    
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.new, context: nil)
        
        print("开始加载网页：\(u)")
        var req = URLRequest(url: u)
        req.timeoutInterval = 10
        webView.load(req)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "estimatedProgress" else {
            return
        }
        
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
    }

}
