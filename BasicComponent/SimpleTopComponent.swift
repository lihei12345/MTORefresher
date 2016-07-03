//
//  SimpleTopComponent.swift
//  MTORefresherDemo
//
//  Created by jason on 7/2/16.
//  Copyright © 2016 mtoteam. All rights reserved.
//

import UIKit
import MTORefresher

public class SimpleTopComponent: UIView, Component {
    private let flipAnimationDuration: NSTimeInterval = 0.18
    
    public var mto_state: ComponentState  = .Idle {
        didSet {
            setNeedsLayout()
            updateUI()
        }
    }
    
    public func mto_contentHeight() -> CGFloat {
        return 60
    }
    
    public lazy var statusLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(14)
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Left
        label.textColor = UIColor.blackColor()
        return label
    }()
    
    public lazy var arrowImageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        let frameworkBundle = NSBundle(forClass: SimpleTopComponent.self)
        let imagePath = frameworkBundle.pathForResource("mto_refresher_pull_refresh_arrow@2x", ofType: "png")
        var image: UIImage?
        if imagePath != nil {
            image = UIImage(contentsOfFile: imagePath!)
        }
        imageView.image = image
        return imageView
    }()
    
    private lazy var activityView: UIActivityIndicatorView = {
        let acitivtyView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        acitivtyView.frame = CGRect(x: 25, y: self.frame.size.height - 38, width: 20, height: 20)
        return acitivtyView
    }()
    
    public init() {
        super.init(frame: CGRectZero)
        addSubview(statusLabel)
        addSubview(arrowImageView)
        addSubview(activityView)
        updateUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
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
    
    private func updateUI() {
        let pullAction: NSTimeInterval -> Void = {duration in
            self.statusLabel.text = "下拉刷新..."
            self.activityView.stopAnimating()
            UIView.animateWithDuration(duration) {
                self.arrowImageView.hidden = false
                self.arrowImageView.layer.transform = CATransform3DIdentity
            }
        }
        
        switch mto_state {
        case .HitTheEnd:
            statusLabel.text = "松开即可刷新..."
            UIView.animateWithDuration(flipAnimationDuration) {
                self.arrowImageView.layer.transform = CATransform3DMakeRotation((CGFloat(M_PI)/180)*180, 0, 0, 1)
            }
        case .Idle:
            pullAction(0)
        case .Pulling:
            pullAction(flipAnimationDuration)
        case .Loading:
            statusLabel.text = "加载中..."
            activityView.startAnimating()
            UIView.animateWithDuration(flipAnimationDuration) {
                self.arrowImageView.hidden = true
            }
        default:
            break
        }
    }
}
