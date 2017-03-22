//
//  DataController.swift
//  truCourse
//
//  Created by Mike Mayer on 3/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import CoreLocation

class DataController : NSObject, CLLocationManagerDelegate
{
  @IBOutlet var dataViewController : DataViewController?
  
  let locationManager = CLLocationManager()
  var trackingEnabled = false
  
  let routes = Routes()
  
  private(set) var currentRoute : Route?
  
  enum State
  {
    case Uninitialized
    case Idle(Bool)     // Authorized
    case Inserting(Int) // insertion index (0 = new start point)
    case Editing(Int)   // editting index
  }
  
  private(set) var state = State.Uninitialized
  
  func start()
  {
    locationManager.delegate = self
    locationManager.allowsBackgroundLocationUpdates = false
    locationManager.requestWhenInUseAuthorization()
  }
  
  //  private override init()
  //  {
  //    super.init()
  //    locationManager.delegate = self
  //    locationManager.requestWhenInUseAuthorization()
  //  }
  
  func updateOptions()
  {
    let options = dataViewController?.options
    locationManager.desiredAccuracy = options?.locationAccuracy ??  5.0
    locationManager.distanceFilter  = options?.locationFilter   ?? 10.0
  }
  
  
  // MARK: - Location Manager Delegate
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
  {
    switch status
    {
    case .authorizedWhenInUse: fallthrough
    case .authorizedAlways:
      print("DC authorized = true")
      trackingEnabled = true
      updateOptions()
      locationManager.startUpdatingLocation()
    default:
      print("DC authorized = false")
      trackingEnabled = false
      locationManager.stopUpdatingLocation()
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
  {
    for loc in locations
    {
      print("DC new location: \(loc.coordinate.longitude) \(loc.coordinate.latitude)")
    }
  }
}
