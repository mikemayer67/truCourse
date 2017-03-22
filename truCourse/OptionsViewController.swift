//
//  OptionsViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/23/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

protocol OptionViewControllerDelegate : NSObjectProtocol
{
  func updateOptions(_ newOptions:Options) -> Void
  func optionsDiffer(from candidateOptions:Options) -> Bool
}

class OptionsViewController: UITableViewController, UITextFieldDelegate
{
  @IBOutlet weak var updateButton        : UIButton!
  @IBOutlet weak var cancelButton        : UIButton!
  
  @IBOutlet weak var topOfScreenSC       : UISegmentedControl!
  @IBOutlet weak var headingAccuracySC   : UISegmentedControl!
  @IBOutlet weak var mapTypeSC           : UISegmentedControl!
  @IBOutlet weak var northTypeSC         : UISegmentedControl!
  @IBOutlet weak var baseUnitSC          : UISegmentedControl!
  @IBOutlet weak var locAccuracySlider   : UISlider!
  @IBOutlet weak var locAccuracyText     : UILabel!
  
  @IBOutlet weak var emailCell           : UITableViewCell!
  @IBOutlet weak var emailField          : UITextField!
  
  var delegate : OptionViewControllerDelegate?
  
  var hasUpdates = false
  
  func enable(_ control: UISegmentedControl, value:Int)
  {
    //    control.alpha = 1.0

    control.isEnabled = true
    control.selectedSegmentIndex = value
  }
  
  func disable(_ control: UISegmentedControl)
  {
    //   control.alpha = 0.2
    control.isEnabled = false
  }
  
  var options = Options()
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    let hasCompass = CLLocationManager.headingAvailable()

    if hasCompass
    {
      enable(topOfScreenSC,     value:options.topOfScreen.rawValue    )
      enable(northTypeSC,       value:options.northType.rawValue    )
      switch(options.topOfScreen)
      {
      case .North: disable(headingAccuracySC)
      case .Heading: enable(headingAccuracySC, value: options.headingAccuracy.index())
      }
    }
    else
    {
      disable(topOfScreenSC)
      disable(headingAccuracySC)
      disable(northTypeSC)
    }
    
    switch options.mapType
    {
    case .standard:
      mapTypeSC.selectedSegmentIndex = 0
    case .satellite:
      mapTypeSC.selectedSegmentIndex = 1
    case .hybrid:
      mapTypeSC.selectedSegmentIndex = 2
    default:
      mapTypeSC.selectedSegmentIndex = 0
    }
    
    baseUnitSC.selectedSegmentIndex  = options.baseUnit.rawValue
    
    locAccuracySlider.value = Float(options.locAccFrac)
    locAccuracyText.text    = options.locationAccuracyString
    
    emailField.text         = options.emailAddress
    
    updateEmailAddressColor(valid:true)
    checkState()
  }
  
  // MARK: - Actions
  
  @IBAction func handleTopOfScreen(_ sender : UISegmentedControl)
  {
    options.topOfScreen = MapOrientation(rawValue: sender.selectedSegmentIndex)!
    
    switch options.topOfScreen
    {
    case .North:   disable(headingAccuracySC)
    case .Heading: enable(headingAccuracySC, value:options.headingAccuracy.index())
    }
    checkState()
  }
  
  @IBAction func handleHeadingAccuracy(_ sender : UISegmentedControl)
  {
    options.headingAccuracy.set(byIndex: sender.selectedSegmentIndex)
    checkState()
  }
  
  @IBAction func handleMapType(_ sender : UISegmentedControl)
  {
    switch(sender.selectedSegmentIndex)
    {
    case 0: options.mapType = .standard
    case 1: options.mapType = .satellite
    case 2: options.mapType = .hybrid
    default: options.mapType = .standard
    }
    
    checkState()
  }
  
  @IBAction func handleNorthType(_ sender : UISegmentedControl)
  {
    self.options.northType = NorthType(rawValue: sender.selectedSegmentIndex)!
    checkState()
  }
  
  @IBAction func handleBaseUnit(_ sender : UISegmentedControl)
  {
    self.options.baseUnit = BaseUnitType(rawValue: sender.selectedSegmentIndex)!
    locAccuracyText.text = options.locationAccuracyString
    checkState()
  }
  
  @IBAction func handleLocationAccuracy(_ sender : UISlider)
  {
    options.locAccFrac = Double(sender.value)
    locAccuracyText.text = options.locationAccuracyString
    checkState()
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
  {
    updateEmailAddressColor(valid: true)
    return true
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    emailField.resignFirstResponder()
    
    if let address = textField.text, address.isEmpty == false
    {
      self.options.setEmailAddress(address)
      updateEmailAddressColor( valid: self.options.emailAddress != nil )
    }
    else
    {
      self.options.emailAddress = nil
      updateEmailAddressColor(valid: true)
    }
    
    checkState()
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
    close()
  }
  
  @IBAction func handleUpdate(_ sender : UIButton)
  {
    if hasUpdates { delegate?.updateOptions(options) }
    close()
  }
  
  func checkState()
  {
    if delegate == nil { hasUpdates = false                                  }
    else               { hasUpdates = delegate!.optionsDiffer(from: options) }
    
    updateButton.setTitle((hasUpdates ? "Apply" : "Back"), for: .normal)
    cancelButton.isEnabled = hasUpdates
    cancelButton.isHidden  = (hasUpdates == false)
  }
  
  func close()
  {
    let nc = self.navigationController as! MainController
    nc.popViewController(animated: true)
  }
  
  // MARK: - Table View delegate
  
  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
  {
    return nil
  }
}
