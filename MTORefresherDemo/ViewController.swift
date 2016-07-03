//
//  ViewController.swift
//  MTORefresherDemo
//
//  Created by jason on 7/1/16.
//  Copyright © 2016 mtoteam. All rights reserved.
//

import UIKit
import MTORefresher

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var refresher: MTORefresher?
    var count: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.whiteColor()
        self.title = "MTORefresher"
        
        self.view.addSubview(tableView)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "重新加载", style: .Done, target: self, action: #selector(didTapReloadBarButtonItem))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "加载更多", style: .Done, target: self, action: #selector(didTapLoadMoreBarButtonItem))
        
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
    }
    
    private func reload() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1*Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.count = 2
            self.tableView.reloadData()
            self.refresher?.stopLoad()
            self.refresher?.canPullUp = true
        }
    }
    
    private func loadMore() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3*Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.count += 20
            self.tableView.reloadData()
            self.refresher?.stopLoad()
        }
    }
    
    func didTapReloadBarButtonItem() {
        self.refresher?.triggerLoad(type: .PullDown)
    }
    
    func didTapLoadMoreBarButtonItem() {
        self.refresher?.triggerLoad(type: .PullUp)
    }
    
    private lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: self.view.bounds, style: .Plain)
        tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
            cell.textLabel?.textColor = UIColor.redColor()
        }
        cell.backgroundColor = UIColor.lightGrayColor()
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
