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
  
  let locationManager  = CLLocationManager()
  
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
    let status = CLLocationManager.authorizationStatus()
    locationManager.requestWhenInUseAuthorization()
/*
    switch status
    {
    case .authorizedWhenInUse: fallthrough
    case .authorizedAlways:
      print("start authorization = true")
      locationManager.startUpdatingLocation()
    default:
      print("start authorization = false")
    }
 */
  }
  
  //  private override init()
  //  {
  //    super.init()
  //    locationManager.delegate = self
  //    locationManager.requestWhenInUseAuthorization()
  //  }
  
  
  
  
  // MARK: - Location Manager Delegate
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
  {
    let enabled = status == .authorizedAlways || status == .authorizedWhenInUse
    
    print("DC new status = \(enabled)")
  }
}
