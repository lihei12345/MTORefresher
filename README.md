# MTORefresher
MTORefresher is a Swift implementation of pull-to-refresh, include pull-down and pull-up. Use 1 line of code can make this. Also you can use Component protocol to custom your own pull-to-refresh Component.

## Install

Now Support Swift 4:
``` 
pod 'MTORefresher', '~> 1.1.0'
# Optional
pod 'MTORefresher/BasicComponent', '~> 1.1.0'
```

For Swift 2.x:
``` 
pod 'MTORefresher', '~> 0.1.1'
# Optional
pod 'MTORefresher/BasicComponent', '~> 0.1.1' 
```

## Basic
### Setup
```Swift
private var refresher: MTORefresher!

// pull down
let topView: SimpleTopComponent = SimpleTopComponent()
// pull up
let bottomView: SimpleBottomComponent = SimpleBottomComponent()
refresher = tableView
    .mto_refresher()
    .add(topView: topView) { [weak self] in
        self?.reload()
    }
    .add(bottomView: bottomView, enableTap: true) { [weak self] in
        self?.loadMore()
    }
// hide has bottom view
refresher?.canPullUp = false
```

### Trigger
```Swift
// trigger pull down
refresher?.triggerLoad(type: .pullDown)
// trigger pull up
refresher?.triggerLoad(type: .pullUp)
```

### Load Data
```Swift
private func reload() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1*Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        self.count = 2
        self.tableView.reloadData()
        // stop loading
        self.refresher?.stopLoad()
        // show bottom view
        self.refresher?.canPullUp = true
        self.refresher?.hasMore = true
    }
}
    
private func loadMore() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3*Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        self.count += 20
        self.tableView.reloadData()
        // stop loading
        self.refresher?.stopLoad()
        let hasMore = (rand()%2) == 0 ? true : false
        // has more data
        self.refresher?.hasMore = hasMore
    }
}
```

## Custom Component

Just create subview that confirms to Componet protocol. See `SimpleTopComponent` and `SimpleBottomComponent` for more! It's very easy to extend.