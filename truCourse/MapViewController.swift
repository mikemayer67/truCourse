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
  
  private(set) var trackingOption  = MKUserTrackingMode.none
  private(set) var trackingEnabled = false
  
  private      var recenterButtonEnabled = true
  
  var trackingMode : MKUserTrackingMode
  {
    return trackingEnabled ? trackingOption : .none
  }
  
   var _visualizationType : VisualizationType { return .MapView }
   var _hasSelection      : Bool              { return false    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    mapView.mapType           = .standard
    mapView.userTrackingMode  = .none
    mapView.showsUserLocation = false
    mapView.showsScale        = true
  }
  
  // MARK: - Options
  
  func _applyOptions(_ options: Options)
  {
    print("applyOptions")
    mapView.mapType = options.mapType
    trackingOption  = options.trackingMode
    
    mapView.showsScale = options.showScale
    
    handleRecenter(nil)
  }
  
  // MARK: - State
  
  func _applyState(_ state: AppState)
  {
    print("applyState")
    switch state
    {
    case .Uninitialized: fallthrough
    case .Disabled:      fallthrough
    case .Paused:
      trackingEnabled = false
    default:
      trackingEnabled = true
    }
    
    recenterButtonEnabled = false
    handleRecenter(nil)
    recenterButtonEnabled = true
  }
  
  // MARK: - Recenter
  
  @IBAction func handleRecenter(_ sender: UIButton?)
  {
    let newTrackingMode = self.trackingMode
    
    mapView.showsUserLocation = (newTrackingMode != .none)
    mapView.setUserTrackingMode(newTrackingMode, animated: true)
    
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
    print("New tracking mode: \(mode.rawValue)")

    guard recenterButtonEnabled else { return }
    
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
