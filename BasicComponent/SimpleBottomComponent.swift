//
//  SimpleBottomComponent.swift
//  MTORefresherDemo
//
//  Created by jason on 7/2/16.
//  Copyright © 2016 mtoteam. All rights reserved.
//

import UIKit

open class SimpleBottomComponent: UIView, Component {
    open var mto_state: ComponentState = .idle {
        didSet {
            setNeedsLayout()
            updateUI()
        }
    }
    
    open func mto_contentHeight() -> CGFloat {
        return 50
    }
    
    public init() {
        super.init(frame: CGRect.zero)
        addSubview(statusLabel)
        updateUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        statusLabel.frame = CGRect(x: 0, y: 15, width: self.bounds.size.width, height: 20)
    }
    
    fileprivate func updateUI() {
        switch mto_state {
        case .hitTheEnd:
            statusLabel.text = "松开即可加载更多..."
        case .idle:
            fallthrough
        case .pulling:
            statusLabel.text = "上拉加载更多..."
        case .loading:
            statusLabel.text = "努力加载中..."
        case .noMore:
            statusLabel.text = "没有更多了..."
        }
    }
    
    open lazy var statusLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.textColor = UIColor.black
        return label
    }()
}

