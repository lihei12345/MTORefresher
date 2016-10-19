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
        self.view.backgroundColor = UIColor.white
        self.title = "MTORefresher"
        
        self.view.addSubview(tableView)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Reload", style: .done, target: self, action: #selector(didTapReloadBarButtonItem))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Load More", style: .done, target: self, action: #selector(didTapLoadMoreBarButtonItem))
        
        let topView: SimpleTopComponent = SimpleTopComponent()
        let bottomView: SimpleBottomComponent = SimpleBottomComponent()
        self.refresher = self.tableView
            .mto_refresher()
            .add(topView: topView) { [weak self] in
                self?.reload()
            }
            .add(bottomView: bottomView, enableTap: true) { [weak self] in
                self?.loadMore()
        }
        self.refresher?.canPullUp = false
        self.refresher?.triggerLoad(type: .pullDown)
    }
    
    fileprivate func reload() {
        /// Simulate network request
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.count = 2
            self.tableView.reloadData()
            self.refresher?.stopLoad()
            self.refresher?.canPullUp = true
            self.refresher?.hasMore = true
        }
    }
    
    fileprivate func loadMore() {
        /// Simulate network request
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.count += 20
            self.tableView.reloadData()
            self.refresher?.stopLoad()
            let hasMore = (arc4random()%2) == 0 ? true : false
            self.refresher?.hasMore = hasMore
        }
    }
    
    func didTapReloadBarButtonItem() {
        refresher?.triggerLoad(type: .pullDown)
    }
    
    func didTapLoadMoreBarButtonItem() {
        refresher?.triggerLoad(type: .pullUp)
    }
    
    fileprivate lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell.textLabel?.textColor = UIColor.red
        }
        cell.backgroundColor = UIColor.cyan
        cell.textLabel?.text = "\((indexPath as NSIndexPath).row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
