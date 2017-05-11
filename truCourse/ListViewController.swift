//
//  ListViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController, DataViewController
{  
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
    print("Don't forget to implement ListViewController.applyOptions")
  }
  
  // MARK: - State
  
  func applyState(_ state: AppState)
  {
    print("Don't forget to implement ListViewController.applyState \(state)")
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
    print("ListView::updateRoute(\(route))")
  }
  
  func updateCandidate(_ cand: Waypoint?)
  {
    print("ListView::updateCandidate(\(cand))")
  }
  
  // MARK: - Popup Actions
  
  @IBAction func handlePopupMenu(_ sender: UIButton) {
  }
  
}
