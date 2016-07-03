//
//  SimpleBottomComponent.swift
//  MTORefresherDemo
//
//  Created by jason on 7/2/16.
//  Copyright © 2016 mtoteam. All rights reserved.
//

import UIKit
import MTORefresher

class SimpleBottomComponent: UIView, Component {
    var mto_state: ComponentState = .Idle {
        didSet {
            setNeedsLayout()
            updateUI()
        }
    }
    
    func mto_contentHeight() -> CGFloat {
        return 50
    }
    
    init() {
        super.init(frame: CGRectZero)
        addSubview(statusLabel)
        updateUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        statusLabel.frame = CGRect(x: 0, y: 15, width: self.bounds.size.width, height: 20)
    }
    
    private func updateUI() {
        switch mto_state {
        case .HitTheEnd:
            statusLabel.text = "松开即可加载更多..."
        case .Idle:
            fallthrough
        case .Pulling:
            statusLabel.text = "上拉加载更多..."
        case .Loading:
            statusLabel.text = "努力加载中..."
        case .NoMore:
            statusLabel.text = "没有更多了..."
        }
    }
    
    private lazy var statusLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(14)
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor()
        return label
    }()
}

