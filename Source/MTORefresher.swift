//
//  MTORefresher.swift
//  MTORefresher
//
//  Created by jason on 7/1/16.
//  Copyright © 2016 mtoteam. All rights reserved.
//

import UIKit

// MARK: - UIScrollView+Extension -

public extension UIScrollView {
    public func mto_refresher() -> MTORefresher {
        return MTORefresher(scrollView: self)
    }
}

// MARK: - ComponentState -

public enum ComponentState {
    case idle, pulling, hitTheEnd, loading, noMore
}

public protocol Component {
    var mto_state: ComponentState { get set }
    func mto_contentHeight() -> CGFloat
}

// MARK: - MTORefresher -

public enum LoadType {
    case idle, pullUp, pullDown
}

open class MTORefresher: UIView {
    
    // MARK: - Life
    
    fileprivate var scrollView: UIScrollView! {
        return self.superview as! UIScrollView
    }
    fileprivate var panGesture: UIPanGestureRecognizer?
    
    public init(scrollView: UIScrollView) {
        super.init(frame: CGRect.zero)
        
        scrollView.addSubview(self)
        addObservers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            removeObservers()
        }
        super.willMove(toSuperview: newSuperview)
    }
    
    // MARK: - Load
    
    fileprivate var loadType: LoadType = .idle
    
    open func triggerLoad(type: LoadType, autoScroll: Bool = true) {
        if loadType != .idle {
            stopLoad()
        }
        if type == .pullDown {
            if !canTriggerLoading() || !canTriggerDownLoading() { return }
            topBeginLoading()
            if autoScroll {
                scrollView.contentOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            }
        } else if type == .pullUp {
            if !canTriggerLoading() || !canTriggerUpLoading() { return }
            bottomBeginLoading()
            let height = realHeight()
            let contentHeight = scrollView.contentSize.height
            if autoScroll && height <= contentHeight {
                let offsetY = contentHeight - height - originalTopInset + scrollView.contentInset.bottom
                scrollView.contentOffset = CGPoint(x: 0, y: offsetY)
            }
        }
    }
    
    open func getLoadType() -> LoadType {
        return loadType
    }
    
    open func stopLoad() {
        if loadType == .pullDown {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(adjustInsetAnimationDuration*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                if self.topView != nil && self.topView.mto_state == .loading {
                    self.stopPullDown()
                }
            }
        } else if bottomView != nil && bottomView.mto_state == .loading && loadType == .pullUp {
            stopPullUp()
        }
    }
    
    // MARK: - Helper
    
    fileprivate let adjustInsetAnimationDuration = 0.3
    
    fileprivate func canTriggerLoading() -> Bool {
        return loadType == .idle && scrollView.isScrollEnabled
    }
    
    fileprivate func realHeight() -> CGFloat {
        return scrollView.frame.size.height - self.originalTopInset
    }
    
    fileprivate func realOffsetY() -> CGFloat {
        return scrollView.contentOffset.y + scrollView.contentInset.top
    }
    
    // MARK: - Pull Down
    
    open var canPullDown: Bool = true {
        didSet {
            (topView as? UIView)?.isHidden = canPullDown
            stopPullDown()
        }
    }
    fileprivate var topView: Component!
    fileprivate var topAction: (() -> Void)?
    fileprivate var originalTopInset: CGFloat = 0
    
    open func add<Top: Component>(topView: Top, action: @escaping () -> Void) -> MTORefresher where Top: UIView {
        self.topView = topView
        self.topAction = action
        originalTopInset = scrollView.contentInset.top
        topView.frame = CGRect(x: 0, y: -300, width: scrollView.frame.size.width, height: 300)
        topView.autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(topView)
        return self
    }
    
    fileprivate func canTriggerDownLoading() -> Bool {
        guard let _ = topView else {
            return false
        }
        return canPullDown
    }
    
    fileprivate func triggerPullDown(_ dragging: Bool) {
        if !canTriggerLoading() || !canTriggerDownLoading() { return }
        
        let offsetY: CGFloat = realOffsetY()
        let threshold = -topView.mto_contentHeight()
        
        if dragging {
            if !scrollView.isDragging {
                return
            }
            if offsetY < threshold {
                topView.mto_state = .hitTheEnd
            } else if offsetY > threshold && offsetY < 0 {
                topView.mto_state = .pulling
            }
        } else {
            if offsetY < threshold {
                topBeginLoading()
            } else {
                topView.mto_state = .idle
            }
        }
    }
    
    fileprivate func topBeginLoading() {
        loadType = .pullDown
        topView.mto_state = .loading
        updateTopInset(true)
        topAction?()
    }
    
    fileprivate func updateTopInset(_ loading: Bool, animated: Bool = true) {
        let duration: TimeInterval = animated ? adjustInsetAnimationDuration : 0
        UIView.animate(withDuration: duration, animations: {
            var insets = self.scrollView.contentInset
            var top: CGFloat = insets.top
            if loading {
                top = self.originalTopInset + self.topView.mto_contentHeight()
            } else {
                top = self.originalTopInset
            }
            insets.top = top
            self.scrollView.contentInset = insets
        })
    }
    
    fileprivate func stopPullDown() {
        guard topView != nil && topView.mto_state == .loading && loadType == .pullDown else { return }
        
        self.loadType = .idle
        self.topView.mto_state = .idle
        self.updateTopInset(false, animated: true)
    }
    
    // MARK: - Pull Up
    
    open var canPullUp: Bool = true {
        didSet {
            (bottomView as? UIView)?.isHidden = !canPullUp
            if oldValue != canPullUp {
                updateBottomInset(enable: canPullUp)
            }
            contentSizeChanged()
        }
    }
    
    open var hasMore: Bool {
        set {
            guard bottomView != nil else { return }
            if !newValue {
                bottomView.mto_state = .noMore
            } else if bottomView.mto_state == .noMore {
                bottomView.mto_state = .idle
            }
        }
        get {
            guard bottomView != nil else { return false }
            return bottomView.mto_state != .noMore
        }
    }
    
    fileprivate var bottomView: Component!
    fileprivate var bottomAction: (() -> Void)?
    fileprivate var originalBottomInset: CGFloat = 0
    
    open func add<Bottom: Component>(bottomView: Bottom, enableTap: Bool, action: @escaping () -> Void) -> MTORefresher where Bottom: UIView {
        self.bottomView = bottomView
        self.bottomAction = action
        originalBottomInset = scrollView.contentInset.bottom
        contentSizeChanged()
        scrollView.addSubview(bottomView)
        updateBottomInset(enable: true)
        
        if enableTap {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBottomComponent))
            bottomView.addGestureRecognizer(tapGesture)
        }
        return self
    }
    
    fileprivate func contentSizeChanged() {
        (bottomView as? UIView)?.frame = CGRect(x: 0, y: scrollView.contentSize.height, width: scrollView.frame.size.width, height: 300)
    }
    
    fileprivate func canTriggerUpLoading() -> Bool {
        guard let bottomView = bottomView else {
            return false
        }
        return canPullUp && bottomView.mto_state != .noMore
    }
    
    fileprivate func triggerPullUp(_ dragging: Bool) {
        if !canTriggerLoading() || !canTriggerUpLoading() { return }
        
        let offsetY = realOffsetY()
        let height = realHeight()
        // Note: contentSize does not include inset
        let contentHeight = scrollView.contentSize.height
        
        if dragging {
            if scrollView.isDragging && contentHeight < height {
                if offsetY - bottomView.mto_contentHeight() >= 0 {
                    bottomView.mto_state = .hitTheEnd
                } else {
                    bottomView.mto_state = .pulling
                }
            } else if contentHeight >= height {
                let threshold: CGFloat = offsetY + height - contentHeight
                if threshold > 0 && bottomView.mto_state != .loading {
                    if threshold > bottomView.mto_contentHeight() {
                        if !scrollView.isTracking {
                            bottomBeginLoading()
                        } else {
                            bottomView.mto_state = .hitTheEnd
                        }
                    } else {
                        bottomView.mto_state = .idle
                    }
                }
            }
        } else {
            var thresold:CGFloat = offsetY
            if contentHeight >= height {
                thresold += (height - contentHeight)
            }
            if thresold >= bottomView.mto_contentHeight() && bottomView.mto_state == .hitTheEnd {
                bottomBeginLoading()
            }
        }
    }
    
    fileprivate func bottomBeginLoading() {
        loadType = .pullUp
        bottomView.mto_state = .loading
        bottomAction?()
    }
    
    fileprivate func updateBottomInset(enable: Bool) {
        var insets = self.scrollView.contentInset
        var bottom: CGFloat = insets.bottom
        if enable {
            bottom = bottom + bottomView.mto_contentHeight()
        } else {
            bottom = originalBottomInset
        }
        insets.bottom = bottom
        scrollView.contentInset = insets
    }
    
    fileprivate func stopPullUp() {
        guard bottomView != nil && bottomView.mto_state == .loading && loadType == .pullUp else { return }
        loadType = .idle
        bottomView.mto_state = .idle
    }
    
    @objc func didTapBottomComponent() {
        triggerLoad(type: .pullUp, autoScroll: false)
    }
    
    // MARK: - Observer
    
    fileprivate var observerContext = 0
    fileprivate let contentOffsetKeyPath = "contentOffset"
    fileprivate let contentSizeKeyPath = "contentSize"
    fileprivate let contentInsetKeyPath = "contentInset"
    fileprivate let panGestureKeyPath = "state"
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath , context == &observerContext {
            switch keyPath {
            case contentOffsetKeyPath:
                scrollViewContentOffsetChanged()
            case contentSizeKeyPath:
                contentSizeChanged()
            case contentInsetKeyPath:
                // Fix iOS 7 inset problem
                let value = change?[NSKeyValueChangeKey.newKey] as? NSValue
                if let newContentInset = value?.uiEdgeInsetsValue {
                    if loadType == .pullDown {
                        if newContentInset.top != topView.mto_contentHeight() {
                            originalTopInset = newContentInset.top - topView.mto_contentHeight()
                        }
                    } else if loadType == .pullUp {
                        if newContentInset.bottom != bottomView.mto_contentHeight() {
                            originalBottomInset = newContentInset.bottom - bottomView.mto_contentHeight()
                        }
                    }
                }
            case panGestureKeyPath:
                if panGesture?.state == .ended {
                    scrollViewContentOffsetChanged(false)
                }
            default:
                break
            }
        }
    }
    
    fileprivate func addObservers() {
        if scrollView != nil {
            scrollView.addObserver(self, forKeyPath: contentOffsetKeyPath, options:.new, context: &observerContext)
            scrollView.addObserver(self, forKeyPath: contentSizeKeyPath, options: .new, context: &observerContext)
            scrollView.addObserver(self, forKeyPath: contentInsetKeyPath, options: .new, context: &observerContext)
            panGesture = scrollView.panGestureRecognizer
            panGesture?.addObserver(self, forKeyPath: panGestureKeyPath, options: .new, context: &observerContext)
        }
    }
    
    fileprivate func removeObservers() {
        if scrollView != nil {
            scrollView.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &observerContext)
            scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath, context: &observerContext)
            scrollView.removeObserver(self, forKeyPath: contentInsetKeyPath, context: &observerContext)
            panGesture?.removeObserver(self, forKeyPath: panGestureKeyPath, context: &observerContext)
            panGesture = nil
        }
    }
    
    fileprivate func scrollViewContentOffsetChanged(_ dragging: Bool = true) {
        triggerPullDown(dragging)
        triggerPullUp(dragging)
    }
}
