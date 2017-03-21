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
    var locationStatus = CLLocationManager.authorizationStatus()
      
    locationManager.requestWhenInUseAuthorization()
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
    print("DC: Authorization Changed: \(status.rawValue)")
  }
}
