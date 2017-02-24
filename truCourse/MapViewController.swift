//
//  MapViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class MapViewController: UIViewController, VisualizationView
{
  @IBOutlet var subView : UIView!
  @IBOutlet var xOffset : UISlider!
  @IBOutlet var yOffset : UISlider!
  
  var visualizationType : VisualizationType { return .MapView }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    updateShadow()
    
    // Do any additional setup after loading the view.
  }
  
  @IBAction func updateShadow(_ updatedSlider:UISlider)
  {
    self.updateShadow()
  }
  
  func updateShadow()->Void
  {
    subView.layer.shadowColor = UIColor.black.cgColor
    subView.layer.shadowOpacity = 1.0
    subView.layer.shadowOffset = CGSize(width: Double(xOffset.value), height: Double(yOffset.value))
    subView.layer.shadowRadius = 10.0
  }
  
}
