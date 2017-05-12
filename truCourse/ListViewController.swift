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
  @IBOutlet weak var listTableView : ListView!
  
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
    tableView.reloadData()
  }
  
  // MARK: - State
  
  func applyState(_ state: AppState)
  {
    tableView.reloadData()
  }
  
  // MARK: - Route update
  
  func updateRoute(_ route: Route)
  {
    tableView.reloadData()
  }
  
  func updateCandidate(_ cand: Waypoint?)
  {
    let dc = DataController.shared
    
    if let ip = dc.insertionIndex
    {
      var rows = [ IndexPath(row:ip-1, section:0) ]
      
      if listTableView.type == .bearing
      {
        if ip == 1 { rows.append( IndexPath(row:dc.route.tail!.index!, section:0) ) }
        else       { rows.append( IndexPath(row:ip-2,                  section:0) ) }
      }
      
      rows.forEach { print("update row \($0.row)") }
      
      tableView.reloadRows(at: rows, with: .fade)
    }
    else
    {
      tableView.reloadData()
    }
  }
  
  // MARK: - Popup Actions
  
  @IBAction func handlePopupMenu(_ sender: UIButton)
  {
  }
  
}
