//
//  RoutesViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 5/5/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

enum RouteSortOrder : Int
{
  case creationDate
  case updateDate
  case proximity
}

protocol RoutesViewControllerDelegate : NSObjectProtocol
{
  func routesViewController(selectedNewRoute route:Route?)
}

class RoutesViewController: UITableViewController
{
  @IBOutlet weak var applyButton: UIButton!
  @IBOutlet weak var applyItem: UIBarButtonItem!
  @IBOutlet weak var cancelButton: UIButton!
  
  var delegate : RoutesViewControllerDelegate?
  
  private var routes = [Route]()
  private var delete = [Route]()
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    applyButton.setTitleColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5), for: .disabled)
  }
  
  override func viewWillAppear(_ animated: Bool)
  {
    routes.removeAll()
    delete.removeAll()
    Routes.shared.routes.forEach { (_, route: Route) in self.routes.append(route) }
  }
  
  @IBAction func handleCancel(_ sender: UIButton)
  {
    close()
  }
  
  @IBAction func handleApply(_ sender: UIButton)
  {
    if let row = tableView.indexPathForSelectedRow?.row
    {
      if row == 0
      {
        delegate?.routesViewController(selectedNewRoute: nil )
      }
      else
      {
        let route = routes[row-1]
        delegate?.routesViewController(selectedNewRoute: route )
      }
    }
    
    delete.forEach { route in Routes.shared.drop(route) }
    
    close()
  }
  
  func close()
  {
    let nc = self.navigationController as! MainController
    nc.popViewController(animated: true)
  }
  
  func checkSelectionState()
  {
    if let selection = tableView.indexPathForSelectedRow
    {
      applyButton.setTitle(selection.row==0 ? "Start" : "Load", for:.normal)
      cancelButton.isEnabled = true
      cancelButton.isHidden = false
    }
    else
    {
      applyButton.setTitle("Back", for:.normal)
      cancelButton.isEnabled = false
      cancelButton.isHidden = true
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return 1 + routes.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let row = indexPath.row
    
    print("cell For Row At: \(row)")
    
    let identifier = ( row == 0  ? "NewRouteCell" : "StoredRouteCell" )
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
        UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
    
    let bgView = UIView()
    bgView.backgroundColor = UIColor(red:0.8, green:0.9, blue: 0.8, alpha:1.0)
    cell.selectedBackgroundView = bgView
    
    if row > 0
    {
      let route = routes[row-1]
        
      cell.textLabel!.text = route.name
      cell.detailTextLabel!.text = "What you lookin' at?"
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
  {
    return indexPath.row > 0
  }
  
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
  {
    if editingStyle == .delete
    {
      guard indexPath.row > 0 && indexPath.row <= routes.count else { return }
      
      let route = routes[indexPath.row-1]
      let alert = UIAlertController(title: "Delete Route",
                                    message: "Please confirm deleting route \(route.name!).",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "delete", style: .destructive,
                                    handler: { _ in
                                      self.delete.append( self.routes.remove(at: indexPath.row-1) )
                                      self.tableView.reloadData() } ) )
      alert.addAction(UIAlertAction(title: "cancel", style: .cancel,
                                    handler: { _ in
                                      self.tableView.reloadRows(at: [indexPath], with: .right) } ) )
      
      self.present(alert, animated: true) { self.checkSelectionState() }
    }
  }
  
  override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath?)
  {
    print("willBeginEditingRowAt \(indexPath?.row)   [\(tableView.indexPathForSelectedRow?.row)")
    applyItem.isEnabled = false
  }
  
  override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?)
  {
    print("didEndEditingRowAt \(indexPath?.row)   [\(tableView.indexPathForSelectedRow?.row)")
    applyItem.isEnabled = true
    checkSelectionState()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt      indexPath: IndexPath) { checkSelectionState() }
  override func tableView(_ tableView: UITableView, didDeselectRowAt    indexPath: IndexPath) { checkSelectionState() }
  override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) { checkSelectionState() }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
}
