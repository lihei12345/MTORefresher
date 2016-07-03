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
    case Idle, Pulling, HitTheEnd, Loading, NoMore
}

public protocol Component {
    var mto_state: ComponentState { get set }
    func mto_contentHeight() -> CGFloat
}

// MARK: - MTORefresher -

public enum LoadType {
    case Idle, PullUp, PullDown
}

public class MTORefresher: UIView {
    
    // MARK: - Life
    
    private weak var scrollView: UIScrollView!
    private weak var panGestrure: UIPanGestureRecognizer!
    
    public init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.panGestrure = scrollView.panGestureRecognizer
        
        super.init(frame: CGRectZero)
        
        scrollView.addSubview(self)
        addObservers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        if newSuperview == nil {
            removeObservers()
            scrollView = nil
            panGestrure = nil
        }
        super.willMoveToSuperview(newSuperview)
    }
    
    // MARK: - Load
    
    private var loadType: LoadType = .Idle
    
    public func triggerLoad(type type: LoadType, autoScroll: Bool = true) {
        if loadType != .Idle {
            stopLoad()
        }
        if type == .PullDown {
            if !canTriggerLoading() || !canTriggerDownLoading() { return }
            topBeginLoading()
            if autoScroll {
                scrollView.contentOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            }
        } else if type == .PullUp {
            if !canTriggerLoading() || !canTriggerUpLoading() { return }
            bottomBeginLoading()
            var height = realHeight()
            let contentHeight = scrollView.contentSize.height
            if autoScroll && height <= contentHeight {
                let offsetY = contentHeight - height - originalTopInset + scrollView.contentInset.bottom
                scrollView.contentOffset = CGPoint(x: 0, y: offsetY)
            }
        }
    }
    
    public func getLoadType() -> LoadType {
        return loadType
    }
    
    public func stopLoad() {
        if loadType == .PullDown {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(adjustInsetAnimationDuration*Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                if self.topView != nil && self.topView.mto_state == .Loading {
                    self.stopPullDown()
                }
            }
        } else if bottomView != nil && bottomView.mto_state == .Loading && loadType == .PullUp {
            stopPullUp()
        }
    }
    
    // MARK: - Helper
    
    private let adjustInsetAnimationDuration = 0.3
    
    private func canTriggerLoading() -> Bool {
        return loadType == .Idle && scrollView.scrollEnabled
    }
    
    private func realHeight() -> CGFloat {
        return scrollView.frame.size.height - self.originalTopInset
    }
    
    private func realOffsetY() -> CGFloat {
        return scrollView.contentOffset.y + scrollView.contentInset.top
    }
    
    // MARK: - Pull Down
    
    public var canPullDown: Bool = true {
        didSet {
            (topView as? UIView)?.hidden = canPullDown
            stopPullDown()
        }
    }
    private var topView: Component!
    private var topAction: (Void -> Void)?
    private var originalTopInset: CGFloat = 0
    
    public func add<Top: Component where Top: UIView>(topView topView: Top, action: Void -> Void) -> MTORefresher {
        self.topView = topView
        self.topAction = action
        originalTopInset = scrollView.contentInset.top
        topView.frame = CGRect(x: 0, y: -300, width: scrollView.frame.size.width, height: 300)
        scrollView.addSubview(topView)
        return self
    }
    
    private func canTriggerDownLoading() -> Bool {
        guard let topView = topView else {
            return false
        }
        return canPullDown
    }
    
    private func triggerPullDown(dragging: Bool) {
        if !canTriggerLoading() || !canTriggerDownLoading() { return }
        
        let offsetY: CGFloat = realOffsetY()
        let threshold = -topView.mto_contentHeight()
        
        if dragging {
            if !scrollView.dragging {
                return
            }
            if offsetY < threshold {
                topView.mto_state = .HitTheEnd
            } else if offsetY > threshold && offsetY < 0 {
                topView.mto_state = .Pulling
            }
        } else {
            if offsetY < threshold {
                topBeginLoading()
            } else {
                topView.mto_state = .Idle
            }
        }
    }
    
    private func topBeginLoading() {
        loadType = .PullDown
        topView.mto_state = .Loading
        updateTopInset(true)
        topAction?()
    }
    
    private func updateTopInset(loading: Bool, animated: Bool = true) {
        let duration: NSTimeInterval = animated ? adjustInsetAnimationDuration : 0
        UIView.animateWithDuration(duration) {
            var insets = self.scrollView.contentInset
            var top: CGFloat = insets.top
            if loading {
                top = self.originalTopInset + self.topView.mto_contentHeight()
            } else {
                top = self.originalTopInset
            }
            insets.top = top
            self.scrollView.contentInset = insets
        }
    }
    
    private func stopPullDown() {
        guard topView != nil && topView.mto_state == .Loading && loadType == .PullDown else { return }
        
        self.loadType = .Idle
        self.topView.mto_state = .Idle
        self.updateTopInset(false, animated: true)
    }
    
    // MARK: - Pull Up
    
    public var canPullUp: Bool = true {
        didSet {
            (bottomView as? UIView)?.hidden = !canPullUp
            if oldValue != canPullUp {
                updateBottomInset(enable: canPullUp)
            }
            contentSizeChanged()
        }
    }
    public var hasMore: Bool = true
    
    private var bottomView: Component!
    private var bottomAction: (Void -> Void)?
    private var originalBottomInset: CGFloat = 0
    
    public func add<Bottom: Component where Bottom: UIView>(bottomView bottomView: Bottom, enableTap: Bool, action: Void -> Void) -> MTORefresher {
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
    
    private func contentSizeChanged() {
        (bottomView as? UIView)?.frame = CGRect(x: 0, y: scrollView.contentSize.height, width: scrollView.frame.size.width, height: 300)
    }
    
    private func canTriggerUpLoading() -> Bool {
        guard let bottomView = bottomView else {
            return false
        }
        return canPullUp && bottomView.mto_state != .NoMore
    }
    
    private func triggerPullUp(dragging: Bool) {
        if !canTriggerLoading() || !canTriggerUpLoading() { return }
        
        let offsetY = realOffsetY()
        let height = realHeight()
        // Note: contentSize does not include inset
        let contentHeight = scrollView.contentSize.height
        
        if dragging {
            if scrollView.dragging && contentHeight < height {
                if offsetY - bottomView.mto_contentHeight() >= 0 {
                    bottomView.mto_state = .HitTheEnd
                } else {
                    bottomView.mto_state = .Pulling
                }
            } else if contentHeight >= height {
                let threshold: CGFloat = offsetY + height - contentHeight
                if threshold > 0 && bottomView.mto_state != .Loading {
                    if threshold > bottomView.mto_contentHeight() {
                        if !scrollView.tracking {
                            bottomBeginLoading()
                        } else {
                            bottomView.mto_state = .HitTheEnd
                        }
                    } else {
                        bottomView.mto_state = .Idle
                    }
                }
            }
        } else {
            var thresold:CGFloat = offsetY
            if contentHeight >= height {
                thresold += (height - contentHeight)
            }
            if thresold >= bottomView.mto_contentHeight() && bottomView.mto_state == .HitTheEnd {
                bottomBeginLoading()
            }
        }
    }
    
    private func bottomBeginLoading() {
        loadType = .PullUp
        bottomView.mto_state = .Loading
        bottomAction?()
    }
    
    private func updateBottomInset(enable enable: Bool) {
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
    
    private func stopPullUp() {
        guard bottomView != nil && bottomView.mto_state == .Loading && loadType == .PullUp else { return }
        loadType = .Idle
        bottomView.mto_state = .Idle
    }
    
    func didTapBottomComponent() {
        triggerLoad(type: .PullUp, autoScroll: false)
    }
    
    // MARK: - Observer
    
    private var observerContext = 0
    private let contentOffsetKeyPath = "contentOffset"
    private let contentSizeKeyPath = "contentSize"
    private let contentInsetKeyPath = "contentInset"
    private let panGestureKeyPath = "state"
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let keyPath = keyPath where context == &observerContext {
            switch keyPath {
            case contentOffsetKeyPath:
                scrollViewContentOffsetChanged()
            case contentSizeKeyPath:
                contentSizeChanged()
            case contentInsetKeyPath:
                // Fix iOS 7 inset problem
                if let newContentInset = change?[NSKeyValueChangeNewKey]?.UIEdgeInsetsValue() {
                    if loadType == .PullDown {
                        if newContentInset.top != topView.mto_contentHeight() {
                            originalTopInset = newContentInset.top - topView.mto_contentHeight()
                        }
                    } else if loadType == .PullUp {
                        if newContentInset.bottom != bottomView.mto_contentHeight() {
                            originalBottomInset = newContentInset.bottom - bottomView.mto_contentHeight()
                        }
                    }
                }
            case panGestureKeyPath:
                if panGestrure != nil && panGestrure.state == .Ended {
                    scrollViewContentOffsetChanged(false)
                }
            default:
                break
            }
        }
    }
    
    private func addObservers() {
        if let scrollView = scrollView,  panGestrure = panGestrure{
            scrollView.addObserver(self, forKeyPath: contentOffsetKeyPath, options:.New, context: &observerContext)
            scrollView.addObserver(self, forKeyPath: contentSizeKeyPath, options: .New, context: &observerContext)
            scrollView.addObserver(self, forKeyPath: contentInsetKeyPath, options: .New, context: &observerContext)
            panGestrure.addObserver(self, forKeyPath: panGestureKeyPath, options: .New, context: &observerContext)
        }
    }
    
    private func removeObservers() {
        if let scrollView = scrollView, let panGestrure = panGestrure {
            removeObserver(scrollView, forKeyPath: contentOffsetKeyPath, context: &observerContext)
            removeObserver(scrollView, forKeyPath: contentSizeKeyPath, context: &observerContext)
            removeObserver(scrollView, forKeyPath: contentInsetKeyPath, context: &observerContext)
            removeObserver(panGestrure, forKeyPath: panGestureKeyPath, context: &observerContext)
        }
    }
    
    private func scrollViewContentOffsetChanged(dragging: Bool = true) {
        triggerPullDown(dragging)
        triggerPullUp(dragging)
    }
}
