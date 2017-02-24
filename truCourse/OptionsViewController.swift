//
//  OptionsViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/23/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

class OptionsViewController: UITableViewController, UITextFieldDelegate
{
  @IBOutlet weak var northTypeController : UISegmentedControl!
  @IBOutlet weak var baseUnitController  : UISegmentedControl!
  @IBOutlet weak var trackingEnabled     : UISwitch!
  @IBOutlet weak var trackingDirection   : UISegmentedControl!
  
  @IBOutlet weak var emailCell           : UITableViewCell!
  @IBOutlet weak var emailField          : UITextField!
  
  var options = Options()
  var canceled = false
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    updateUI(with:options)
    updateEmailAddressColor(valid:true)
    canceled = false
  }
  
  func updateUI(with options: Options)
  {
    northTypeController.selectedSegmentIndex = options.northType.rawValue
    baseUnitController.selectedSegmentIndex  = options.baseUnit.rawValue
    
    trackingEnabled.isOn                     = options.trackingEnabled
    trackingDirection.selectedSegmentIndex   = options.headingUp ? 0 : 1
    
    emailField.text                          = options.emailAddress
    
    updateTrackingControllers(for: options)
  }
  
  private func updateTrackingControllers(for options:Options)
  {
    let t1 = options.headingAvailable
    let t2 = t1 && options.trackingEnabled
    
    trackingEnabled.isEnabled = t1
    trackingEnabled.alpha     = (t1 ? 1.0 : 0.2)
    
    trackingDirection.isEnabled = t2
    trackingDirection.alpha     = (t2 ? 1.0 : 0.2)
  }
  
  
  
  // MARK: - Actions
  
  @IBAction func handleNorthType(_ sender : UISegmentedControl)
  {
    self.options.northType = NorthType(rawValue: sender.selectedSegmentIndex)!
  }
  
  @IBAction func handleBaseUnit(_ sender : UISegmentedControl)
  {
    self.options.baseUnit = BaseUnitType(rawValue: sender.selectedSegmentIndex)!
  }
  
  @IBAction func handleTrackingEnabled(_ sender : UISwitch)
  {
    self.options.trackingEnabled = sender.isOn
    updateTrackingControllers(for: self.options)
  }
  
  @IBAction func handleTrackingDirection(_ sender : UISegmentedControl)
  {
    self.options.headingUp = ( sender.selectedSegmentIndex == 1 )
  }
  
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
  {
    updateEmailAddressColor(valid: true)
    return true
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    emailField.resignFirstResponder()
    self.options.setEmailAddress(textField.text)
    updateEmailAddressColor( valid: self.options.emailAddress != nil )
    return true
  }
  
  func updateEmailAddressColor(valid:Bool) -> Void
  {
    let errColor = UIColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 1.0)
    
    let bg = ( valid ? nil : errColor )
    let fg = ( valid ? UIColor.black : errColor )
    
    emailCell.backgroundColor = bg
    emailField.textColor = fg
  }
  
  @IBAction func handleCancel(_ sender : UIButton)
  {
    let nc = self.navigationController as! PrimaryNavigationController
    nc.closeOptions(self, options: nil)
  }
  
  @IBAction func handleUpdate(_ sender : UIButton)
  {
    let nc = self.navigationController as! PrimaryNavigationController
    nc.closeOptions(self, options: self.options)
  }
}
