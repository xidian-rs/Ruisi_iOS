//
//  RSRefreshControl.swift
//  Ruisi
//
//  Created by yang on 2017/12/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class RSRefreshControl: UIControl {
    private let refreshOffsetHeight: CGFloat = 64 // 刷新位置临界点
    
    // 父scrollView
    private weak var scrollView: UIScrollView?
    private lazy var progress =  UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private lazy var titleLabel =  UILabel()
    private var initTopInset: CGFloat = 0
    
    // 当前的状态
    private var refreshState = RSRefreshState.normal {
        didSet {
            switch refreshState {
            case .normal:
                title = "下拉刷新"
                progress.stopAnimating()
            case .dragging:
                title = "释放立即刷新"
                progress.stopAnimating()
            case .refreshing:
                title = "正在刷新..."
                
                progress.startAnimating()
            case .endding(let title):
                if let t = title {
                    self.title = t
                }
                progress.stopAnimating()
            }
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    public init() {
        super.init(frame: CGRect.zero)
        
        // 超出不显示
        //clipsToBounds = true
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        progress.isUserInteractionEnabled = false
        progress.hidesWhenStopped = true
        progress.stopAnimating()
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.darkGray
        titleLabel.text = "下拉刷新"
        titleLabel.isUserInteractionEnabled = false
        titleLabel.textAlignment = .center
        
        addSubview(progress)
        addSubview(titleLabel)
        
        progress.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: progress, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: -70))
        addConstraint(NSLayoutConstraint(item: progress, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -22))
        
        addConstraint(NSLayoutConstraint(item: progress, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 20))
        addConstraint(NSLayoutConstraint(item: progress, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 20))
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 12))
        addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -20))
        
        addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 140))
        addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 24))
    }
    
    // newSuperview 不为nil则是加到父view 为nil代表移除
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        guard let sv = newSuperview as? UIScrollView else {
            return
        }
        
        initTopInset = sv.contentInset.top
        scrollView = sv
        scrollView?.addObserver(self, forKeyPath: "contentOffset", options: [], context:nil)
    }
    
    override func removeFromSuperview() {
        // 注意 superview
        superview?.removeObserver(self, forKeyPath: "contentOffset")
        super.removeFromSuperview()
    }
    
    // 观察的对象改变的时候调用
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let sv = scrollView else {
            return
        }
        
        // contentOffset init -64
        let height = -(sv.contentInset.top + sv.contentOffset.y)
        if height < 64 {
            return
        }
        
        // 设置刷新控件的frame
        self.frame = CGRect(x: 0, y: -height, width: sv.bounds.width, height: height)
        
        switch refreshState {
        case .endding(title: _), .refreshing:
            return
        default:
            break
        }
        
        
        // 判断到达刷新的临界点
        if sv.isDragging {
            switch refreshState {
            case .normal:
                if (height > refreshOffsetHeight + 64) {
                    // 正好超过临界点
                    refreshState = .dragging
                }
            case .dragging:
                if height <= refreshOffsetHeight + 64 {
                    // 正好小于临界点
                    refreshState = .normal
                }
            default:
                break
            }
        } else {
            // 放手 的时候超过临界点
            switch refreshState {
            case .dragging:
                // 撒手的时候滚动到这儿的时候开始刷新
                if height <= refreshOffsetHeight + 64 {
                    beginRefreshing()
                    //发送通知
                    sendActions(for: .valueChanged)
                }
            default:
                break
            }
        }
    }
    
    open var isRefreshing: Bool {
        switch refreshState {
        case .refreshing:
            return true
        default:
            return false
        }
    }
    
    open func beginRefreshing() {
        guard let sv = scrollView else {
            return
        }
        
        if isRefreshing {
            return
        }
        
        refreshState = .refreshing
        var inset = sv.contentInset
        inset.top = initTopInset + refreshOffsetHeight
        sv.contentInset = inset
    }
    
    open func endRefreshing(message: String? = nil) {
        guard let sv = scrollView else {
            return
        }
        if !isRefreshing {
            return
        }
        // 如果要显示刷新后的状态则暂停0.8s
        if let m = message {
            refreshState = .endding(title: m)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.45) {
                var inset = sv.contentInset
                inset.top = self.initTopInset
                sv.contentInset = inset
                self.refreshState = .normal
            }
        } else {
            self.refreshState = .normal
            var inset = sv.contentInset
            inset.top = initTopInset
            sv.contentInset = inset
        }
    }
}
