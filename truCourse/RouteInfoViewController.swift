//
//  RouteInfoViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 5/3/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

protocol RouteInfoViewDelegate
{
  func route(for controller:RouteInfoViewController) -> Route?
  func saveRoute(withName name:String, description:String?, keepOpen:Bool)
}

class RouteInfoViewController: PopupViewController, UITextFieldDelegate, UITextViewDelegate
{
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var keepOpenSwitch: UISwitch!
  @IBOutlet weak var saveButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  var name  : String?
  var desc  : String?
  
  var delegate : RouteInfoViewDelegate?
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    nameTextField.layer.borderColor = UIColor.gray.cgColor
    nameTextField.layer.cornerRadius = 5.0
    nameTextField.layer.borderWidth = 1.0

    descriptionTextView.layer.borderColor = UIColor.gray.cgColor
    descriptionTextView.layer.cornerRadius = 5.0
    descriptionTextView.layer.borderWidth = 1.0
    
    saveButton.layer.cornerRadius = 3.0
    saveButton.layer.borderWidth = 1.0
    saveButton.layer.borderColor = UIColor.gray.cgColor
    
    cancelButton.layer.cornerRadius = 3.0
    cancelButton.layer.borderWidth = 1.0
    cancelButton.layer.borderColor = UIColor.gray.cgColor
    
    keepOpenSwitch.isOn = true
    
    if let route = delegate?.route(for: self)
    {
      name = route.name
      nameTextField.text = name
      
      desc = route.description
      descriptionTextView.text = desc
      
      keepOpenSwitch.isOn = route.lastSaved == nil
    }
    
    watchName()
    watchDescription()
  }
  
  func watchName()
  {
    if name == nil || name!.isEmpty
    {
      nameTextField.text = "[required]"
      nameTextField.textColor = UIColor.red
      saveButton.isEnabled = false
    }
    else
    {
      nameTextField.textColor = UIColor.black
      saveButton.isEnabled = true
    }
  }
  
  func watchDescription()
  {
    if desc == nil || desc!.isEmpty
    {
      descriptionTextView.text = "[optional]"
      descriptionTextView.textColor = UIColor.gray
    }
    else
    {
      descriptionTextView.textColor = UIColor.black
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
  {
    if name == nil || name!.isEmpty
    {
      nameTextField.text = nil
      nameTextField.textColor = UIColor.black
    }
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField)
  {
    name = nameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    watchName()
  }
  
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
  {
    if desc == nil || desc!.isEmpty
    {
      descriptionTextView.text = nil
      descriptionTextView.textColor = UIColor.black
    }
    return true
  }
  
  func textViewDidEndEditing(_ textView: UITextView)
  {
    desc = descriptionTextView.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    watchDescription()
  }
  
  func textViewDidChange(_ textView: UITextView)
  {
    desc = descriptionTextView.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
  
  @IBAction func handleCancel(_ sender: UIButton)
  {
    self.dismiss(animated: true)
  }
  
  @IBAction func handleSave(_ sender: UIButton)
  {
    self.dismiss(animated: true)
    delegate?.saveRoute(withName: name!, description: desc, keepOpen: keepOpenSwitch.isOn)
  }
  
  @IBAction func handleBackgroundTouch(_ sender: UIControl)
  {
    self.view.endEditing(true)
  }
  
  @IBAction func handleNameChanged(_ sender: UITextField)
  {
    name = nameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    saveButton.isEnabled = ( ( name == nil || name!.isEmpty ) == false )
  }

}
