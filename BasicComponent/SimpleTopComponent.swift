//
//  SimpleTopComponent.swift
//  MTORefresherDemo
//
//  Created by jason on 7/2/16.
//  Copyright © 2016 mtoteam. All rights reserved.
//

import UIKit

open class SimpleTopComponent: UIView, Component {
    fileprivate let flipAnimationDuration: TimeInterval = 0.18
    
    open var mto_state: ComponentState  = .idle {
        didSet {
            setNeedsLayout()
            updateUI()
        }
    }
    
    open func mto_contentHeight() -> CGFloat {
        return 60
    }
    
    open lazy var statusLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.textAlignment = .left
        label.textColor = UIColor.black
        return label
    }()
    
    open lazy var arrowImageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        let frameworkBundle = Bundle(for: SimpleTopComponent.self)
        let imagePath = frameworkBundle.path(forResource: "mto_refresher_pull_refresh_arrow@2x", ofType: "png")
        var image: UIImage?
        if imagePath != nil {
            image = UIImage(contentsOfFile: imagePath!)
        }
        imageView.image = image
        return imageView
    }()
    
    fileprivate lazy var activityView: UIActivityIndicatorView = {
        let acitivtyView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        acitivtyView.frame = CGRect(x: 25, y: self.frame.size.height - 38, width: 20, height: 20)
        return acitivtyView
    }()
    
    public init() {
        super.init(frame: CGRect.zero)
        addSubview(statusLabel)
        addSubview(arrowImageView)
        addSubview(activityView)
        updateUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.size.width
        let height = self.bounds.size.height
        let contentHeight = mto_contentHeight()
        
        arrowImageView.frame = CGRect(x: width/2 - 60, y: height - (contentHeight - 22)/2 - 22, width: 22, height: 22)
        activityView.frame = arrowImageView.frame
        statusLabel.frame = CGRect(
            x: arrowImageView.frame.origin.x + arrowImageView.frame.size.width + 8,
            y: height - (contentHeight - 15)/2 - 15,
            width: width,
            height: 15
        )
    }
    
    fileprivate func updateUI() {
        let pullAction: (TimeInterval) -> Void = {duration in
            self.statusLabel.text = "下拉刷新..."
            self.activityView.stopAnimating()
            UIView.animate(withDuration: duration, animations: {
                self.arrowImageView.isHidden = false
                self.arrowImageView.layer.transform = CATransform3DIdentity
            }) 
        }
        
        switch mto_state {
        case .hitTheEnd:
            statusLabel.text = "松开即可刷新..."
            UIView.animate(withDuration: flipAnimationDuration, animations: {
                self.arrowImageView.layer.transform = CATransform3DMakeRotation((CGFloat(Double.pi)/180)*180, 0, 0, 1)
            }) 
        case .idle:
            pullAction(0)
        case .pulling:
            pullAction(flipAnimationDuration)
        case .loading:
            statusLabel.text = "加载中..."
            activityView.startAnimating()
            UIView.animate(withDuration: flipAnimationDuration, animations: {
                self.arrowImageView.isHidden = true
            }) 
        default:
            break
        }
    }
}
