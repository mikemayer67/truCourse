//
//  RenumberViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 4/26/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

protocol RenumberViewDelegate : UIPickerViewDelegate, UIPickerViewDataSource
{
  func title(for view:RenumberViewController) -> String?
  func renumberView(_ view:RenumberViewController, didSelect row:Int)
}


class RenumberViewController: PopupViewController
{
  @IBOutlet weak var pickerView: UIPickerView!
  @IBOutlet weak var titleLabel: UILabel!
  
  weak var delegate : RenumberViewDelegate?
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    pickerView.delegate   = delegate
    pickerView.dataSource = delegate
  }
  
  override func viewWillAppear(_ animated: Bool)
  {
    titleLabel.text = delegate?.title(for:self)
  }
  
  @IBAction func handle_cancel(_ sender: UIButton)
  {
    self.dismiss(animated: true)
  }
  
  @IBAction func handle_done(_ sender: UIButton)
  {
    let index = pickerView.selectedRow(inComponent: 0)
    delegate?.renumberView(self, didSelect: index)
    
    self.dismiss(animated: true)
  }
}
