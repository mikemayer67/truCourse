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
  
  var trackingMode = MKUserTrackingMode.none
  
  var visualizationType : VisualizationType { return .MapView }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  // MARK: - Options
  
  func applyOptions(_ options: Options)
  {
    mapView.mapType = options.mapType
    trackingMode    = options.trackingMode
  }
  
  
  
  func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
  {
    print("New Tracking Mode: \(trackingMode) -> \(mode)")
  }
  
}
