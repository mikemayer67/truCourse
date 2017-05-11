//
//  BearingViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class BearingViewController: UITableViewController, DataViewController
{
  weak var dataController : DataController!
  
  var hasSelection: Bool
  {
    return self.tableView.indexPathForSelectedRow != nil
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
  }
  
  // MARK: - Options
  
  func applyOptions()
  {
    print("Don't forget to implement BearingViewController.applyOptions")
  }
  
  // MARK: - State
  
  func applyState(_ state: AppState)
  {
    print("Don't forget to implement BearingViewController.applyState \(state)")
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 0
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return 0
  }
  
  // MARK: - Route update
  
  func updateRoute(_ route: Route)
  {
    print("BearingView::updateRoute(\(route))")
  }
  
  func updateCandidate(_ cand: Waypoint?)
  {
    print("BearingView::updateCandidate(\(cand))")
  }
}
