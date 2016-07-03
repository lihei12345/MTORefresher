# MTORefresher
MTORefresher is a Swift implementation of pull-to-refresh. It's very easy to use and extend.

## Use
```Swift
        let topView: SimpleTopComponent = SimpleTopComponent()
        let bottomView: SimpleBottomComponent = SimpleBottomComponent()
        refresher = tableView
            .mto_refresher()
            .add(topView: topView) { [weak self] in
                self?.reload()
            }
            .add(bottomView: bottomView, enableTap: true) { [weak self] in
                self?.loadMore()
            }
        refresher?.canPullUp = false
        refresher?.triggerLoad(type: .PullDown)
```