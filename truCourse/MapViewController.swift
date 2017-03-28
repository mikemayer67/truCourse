//
//  MapViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, VisualizationView, MKMapViewDelegate
{
  @IBOutlet weak var mapView        : MKMapView!
  @IBOutlet weak var recenterButton : UIButton!
  
  private(set) var trackingMode = MKUserTrackingMode.none
  
  var visualizationType : VisualizationType { return .MapView }
  var hasSelection      : Bool              { return false    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    mapView.mapType          = .standard
    mapView.userTrackingMode = .none
  }
  
  // MARK: - Options
  
  func applyOptions(_ options: Options)
  {
    mapView.mapType = options.mapType
    trackingMode    = options.trackingMode
    
    handleRecenter(recenterButton)
  }
  
  // MARK: - Recenter
  
  @IBAction func handleRecenter(_ sender: UIButton)
  {
    mapView.setUserTrackingMode(trackingMode, animated: true)
    recenterButton.isEnabled = false

    UIView.animate(withDuration: 0.35,
                   animations: { self.recenterButton.alpha = 0.0 })
    {
      (finished:Bool) in
      self.recenterButton.isHidden = true
    }
  }
  
  
  
  // MARK: - Map View delegate methods
  
  func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
  {    
    recenterButton.alpha = 0.0
    recenterButton.isHidden = false
    UIView.animate(withDuration: 0.35,
                   animations: { self.recenterButton.alpha = 1.0 })
    {
      (finished:Bool) in
      self.recenterButton.isEnabled = true
    }
  }
  
}
