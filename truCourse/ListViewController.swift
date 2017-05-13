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
    
    let n = dc.tableView(self.tableView, numberOfRowsInSection: 0)
    let nt = tableView.numberOfRows(inSection: 0)
    
    if let ip = dc.insertionIndex,
      n == nt,
      n > 1
    {
      var rows = [ IndexPath(row:ip-1, section:0) ]
      
      if listTableView.type == .bearing
      {
        if ip == 1 { rows.append( IndexPath(row:dc.route.tail!.index!, section:0) ) }
        else       { rows.append( IndexPath(row:ip-2,                  section:0) ) }
      }
      
      tableView.reloadRows(at: rows, with: .fade)
    }
    else
    {
      tableView.reloadSections([0], with: .fade)
    }
  }
  
  // MARK: - Popup Actions
  
  @IBAction func handlePopupMenu(_ sender: UIButton)
  {
    let actions = DataController.shared.popupActions(for: sender.tag)
    
    if actions == nil { return }
    
    let alert = UIAlertController( title: "Post \(index) selected",
      message: "What do you want to do?",
      preferredStyle: .actionSheet)
    
    actions!.forEach { alert.addAction($0) }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    self.present(alert, animated:true)
  }
  
  @IBAction func handleUserPopupMenu(_ sender: UIButton)
  {
    DataController.shared.pickInsertionIndex()
  }
}
