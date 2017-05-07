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
  func optionViewController(updatedOptions:Options)
}

class OptionsViewController: UITableViewController
{
  @IBOutlet weak var updateButton        : UIButton!
  @IBOutlet weak var cancelButton        : UIButton!
  
  @IBOutlet weak var mapTypeSC           : UISegmentedControl!
  @IBOutlet weak var autoScaleSwitch     : UISwitch!
  @IBOutlet weak var showScaleSwitch     : UISwitch!
  @IBOutlet weak var northTypeSC         : UISegmentedControl!
  @IBOutlet weak var baseUnitSC          : UISegmentedControl!
  @IBOutlet weak var locAccuracySlider   : UISlider!
  @IBOutlet weak var locAccuracyText     : UILabel!
  @IBOutlet weak var minPostSepSlider    : UISlider!
  @IBOutlet weak var minPostSepText      : UILabel!
  @IBOutlet weak var shakeUndoSwitch     : UISwitch!
  @IBOutlet weak var shakeUndoSlider     : UISlider!
  @IBOutlet weak var shakeUndoText       : UILabel!
  
  let undoTimeoutValues : [Double?] = [ 1.0, 2.0, 3.0, 5.0, 10.0, 15.0, 30.0, 60.0, 120.0, 300.0, nil ]
  
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
    
    if CLLocationManager.headingAvailable()
    {
      enable(northTypeSC, value:options.northType.rawValue )
    }
    else
    {
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
    
    autoScaleSwitch.isOn         = options.autoScale
    showScaleSwitch.isOn         = options.showScale
    
    baseUnitSC.selectedSegmentIndex  = options.baseUnit.rawValue
    
    locAccuracySlider.value      = Float(options.locAccFrac)
    locAccuracyText.text         = options.locationAccuracyString
    
    minPostSepSlider.value       = Float(options.postSepFrac)
    minPostSepText.text          = options.minPostSeparationString
    
    shakeUndoSwitch.isOn         = options.canShakeUndo
    shakeUndoSlider.isEnabled    = options.canShakeUndo
    shakeUndoSlider.minimumValue = 0.0
    shakeUndoSlider.maximumValue = Float(undoTimeoutValues.count - 1)
    shakeUndoText.isHidden       = options.canShakeUndo == false
    self.shakeUndoTimeout        = options.shakeUndoTimeout
    
    checkState()
  }
  
  var shakeUndoTimeout : Double?
  {
    get {
      let i = Int( shakeUndoSlider.value + 0.5 )
      let t = undoTimeoutValues[i]
      return t
    }
    set {
      let n = undoTimeoutValues.count - 1
      if let t = newValue
      {
        var i  = n-1
        while(i>0 && t < undoTimeoutValues[i]!) { i = i - 1 }
        shakeUndoSlider.value = Float(i)
        setUndoText(i)
      }
      else
      {
        setUndoText(n)
      }
    }
  }
  
  func setUndoText(_ index : Int)
  {
    if let tt = undoTimeoutValues[index]
    {
      if( tt >= 60.0 ) { shakeUndoText.text = String(format: "%d min", Int(tt / 60.0 + 0.5 ) ) }
      else             { shakeUndoText.text = String(format: "%d sec", Int(tt)) }
    }
    else
    {
      shakeUndoText.text = "never"
    }
  }
  
  // MARK: - Actions
  
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
  
  @IBAction func handleAutoScale(_ sender : UISwitch)
  {
    options.autoScale = sender.isOn
    checkState()
  }
  
  @IBAction func handleShowScale(_ sender : UISwitch)
  {
    options.showScale = sender.isOn
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
    minPostSepText.text  = options.minPostSeparationString
    checkState()
  }
  
  @IBAction func handleLocationAccuracy(_ sender : UISlider)
  {
    options.locAccFrac = Double(sender.value)
    locAccuracyText.text = options.locationAccuracyString
    checkState()
  }
  
  @IBAction func handleMinPostSeparation(_ sender : UISlider)
  {
    options.postSepFrac = Double(sender.value)
    minPostSepText.text  = options.minPostSeparationString
    checkState()
  }
  
  @IBAction func handleUndoEnable(_ sender : UISwitch)
  {
    options.canShakeUndo      = sender.isOn
    shakeUndoSlider.isEnabled = sender.isOn
    shakeUndoText.isHidden    = sender.isOn == false
    checkState()
  }
  
  @IBAction func handleUndoTimeout(_ sender : UISlider)
  {
    let index = Int(sender.value + 0.5)
    options.shakeUndoTimeout = undoTimeoutValues[index]
    setUndoText(index)
    checkState()

  }
  
  @IBAction func handleUndoTimeoutDone(_ sender : UISlider)
  {
    let index = Int(sender.value + 0.5)
    sender.value = Float(index)
    options.shakeUndoTimeout = undoTimeoutValues[index]
    setUndoText(index)
    checkState()
  }
  
  @IBAction func handleCancel(_ sender : UIButton)
  {
    close()
  }
  
  @IBAction func handleUpdate(_ sender : UIButton)
  {
    if hasUpdates { delegate?.optionViewController(updatedOptions: options) }
    close()
  }
  
  func checkState()
  {
    if delegate == nil { hasUpdates = false                                }
    else               { hasUpdates = options.differ(from: Options.shared) }
    
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
  
  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return 3
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    switch(section)
    {
    case 0: return "Map"
    case 1:
      if CLLocationManager.headingAvailable() && Options.shared.declination != nil
      {
        return "Route (declination: \(Options.shared.declination!.dms))"
      }
      else
      {
        return "Route (declination not available)"
      }
    case 2: return "Undo"
    default: return nil
    }
  }
}
