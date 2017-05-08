//
//  RoutesViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 5/5/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import CoreLocation

extension Int
{
  var detailString : String
  {
    if self < 100 { return "\(self)" }
    
    var v = self
    var s = 1
    while v >= 100 { v = v/10; s = 10*s }
    return "\(v*s)"
  }
}

extension Double
{
  var detailString : String
  {
    if self > 9.4 { return Int(self+0.5).detailString }
    return "\(0.1 * Double( Int(10.0*self + 0.5) ) )"
  }
}

func detailDist(_ dist : Double) -> String
{
  switch Options.shared.baseUnit
  {
  case .English:
    let feet = Int( dist / 0.3048 + 0.5 )
    if feet <= 5000 { return "\(feet.detailString) ft" }
    else
    {
      let miles = ( Double(feet) / 5280.0 )
      return "\(miles.detailString) mile"
    }
    
  case .Metric:
    if dist < 1000.0
    {
      let m = Int( dist + 0.5 )
      return "\(m.detailString) m"
    }
    else
    {
      let km = 0.001 * dist
      return "\(km.detailString) km"
    }
  }
}

enum RouteSortType : Int
{
  case proximity = 0
  case date = 1
}

enum RouteSortOrder : Int
{
  case forward = 0
  case reverse = 1
}

protocol RoutesViewControllerDelegate : NSObjectProtocol
{
  func getCurrentLocation() -> CLLocation?
  func routesViewController(selectedNewRoute route:Route?)
}

class RoutesViewController: UITableViewController
{
  @IBOutlet weak var applyButton: UIButton!
  @IBOutlet weak var applyItem: UIBarButtonItem!
  @IBOutlet weak var cancelButton: UIButton!
  
  var sortTypeSeg  : UISegmentedControl!
  var sortOrderSeg : UISegmentedControl!
  
  var sortItems : [UIBarButtonItem]!
  var sortType  = RouteSortType.proximity
  var sortOrder = RouteSortOrder.forward
  
  var delegate : RoutesViewControllerDelegate?
  
  private var routes = [Route]()
  private var delete = [Route]()
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    applyButton.setTitleColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5), for: .disabled)
    
    sortTypeSeg = UISegmentedControl(items: ["proximity","date"])
    sortTypeSeg.tintColor = UIColor.white
    sortTypeSeg.addTarget(self, action: #selector(handleSort(_:)), for: .valueChanged)
    
    sortOrderSeg = UISegmentedControl(items:["0","1"])
    sortOrderSeg.tintColor = UIColor.white
    sortOrderSeg.addTarget(self, action: #selector(handleSort(_:)), for: .valueChanged)
    
    let sortTypeItem = UIBarButtonItem(customView: sortTypeSeg)
    let sortOrderItem = UIBarButtonItem(customView: sortOrderSeg)
    let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    sortItems = [space, sortTypeItem, space, sortOrderItem, space]
  }
  
  override func viewWillAppear(_ animated: Bool)
  {
    routes.removeAll()
    delete.removeAll()
    Routes.shared.routes.forEach { (_, route: Route) in self.routes.append(route) }
  }
  
  override func viewDidAppear(_ animated: Bool)
  {
    let here = delegate?.getCurrentLocation()
    if here == nil
    {
      sortType = .date
      sortTypeSeg.isEnabled = false
    }
    else
    {
      sortTypeSeg.isEnabled = true
    }
    
    sortTypeSeg.selectedSegmentIndex = sortType.rawValue
    sortOrderSeg.selectedSegmentIndex = sortOrder.rawValue
    
    setOrderTitles()
    sortRoutes()
    
    navigationController?.toolbar?.setItems(sortItems, animated: true)
  }
  
  func setOrderTitles()
  {
    switch sortType
    {
    case .date:
      sortOrderSeg.setTitle("newest", forSegmentAt: 0)
      sortOrderSeg.setTitle("oldest", forSegmentAt: 1)
    case .proximity:
      sortOrderSeg.setTitle("nearest", forSegmentAt: 0)
      sortOrderSeg.setTitle("farthest", forSegmentAt: 1)
    }
  }
  
  func handleSort(_ sender:UISegmentedControl)
  {
    switch sender
    {
    case sortTypeSeg:
      sortType = RouteSortType(rawValue: sender.selectedSegmentIndex)!
      setOrderTitles()
    case sortOrderSeg:
      sortOrder = RouteSortOrder(rawValue: sender.selectedSegmentIndex)!
    default:
      break
    }
    sortRoutes()
    tableView.reloadData()
  }
  
  func sortRoutes()
  {
    switch sortType
    {
    case .date:
      
      let test = { (a:Route,b:Route)->Bool in
        if a.lastSaved == nil
        {
          if b.lastSaved == nil { return a.created > b.created }
          else                  { return true }
        }
        else
        {
          if b.lastSaved == nil { return false }
          else                  { return a.lastSaved! > b.lastSaved! }
        }
      }
      
      switch sortOrder
      {
      case .forward:
        routes.sort { (a:Route, b:Route)->Bool in return test(a,b) }
      case .reverse:
        routes.sort { (a:Route, b:Route)->Bool in return test(a,b) == false }
      }
      
    case .proximity:
      
      if let here = delegate?.getCurrentLocation()
      {
        switch sortOrder
        {
        case .forward:
          routes.sort { (a:Route, b:Route)->Bool in return a.proximity(to:here) < b.proximity(to:here) }
        case .reverse:
          routes.sort { (a:Route, b:Route)->Bool in return a.proximity(to:here) > b.proximity(to:here) }
        }
      }
    }
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
      
      var detailText = ""
      
      if let dist = route.distance {
        detailText.append( detailDist(dist))
        detailText.append( " long, ")
      }
      
      if let here = delegate?.getCurrentLocation()
      {
        let proximity = route.proximity(to: here)
        detailText.append( detailDist( proximity ) )
        detailText.append( " away, " )
      }
      
      let formatter = DateFormatter()
      formatter.timeStyle = .none
      formatter.dateStyle = .short
      let created = formatter.string(from: route.created)
      detailText.append("created \(created) ")
      
      cell.detailTextLabel!.text = detailText
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
    applyItem.isEnabled = false
  }
  
  override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?)
  {
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
