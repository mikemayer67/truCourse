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
  func title(for vvc:RenumberViewController) -> String?
  func initialRow(for vc:RenumberViewController) -> Int
  func renumberView(_ vc:RenumberViewController, didSelect row:Int)
}


class RenumberViewController: PopupViewController
{
  @IBOutlet weak var pickerView: UIPickerView!
  @IBOutlet weak var titleLabel: UILabel!
  
  weak var delegate : RenumberViewDelegate?
  
  var originalPost : Int = 0
  {
    didSet { pickerView?.tag = originalPost }
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    pickerView.delegate   = delegate
    pickerView.dataSource = delegate
    
    pickerView.tag        = originalPost
  }
  
  override func viewWillAppear(_ animated: Bool)
  {
    let row = delegate?.initialRow(for: self) ??
      ( pickerView.numberOfRows(inComponent: 0) - 1 )
    
    titleLabel.text = delegate?.title(for:self)
    pickerView.selectRow(row, inComponent: 0, animated: true)
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
