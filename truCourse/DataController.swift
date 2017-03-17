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
  static var shared = DataController()
  
  var dataViewController : DataViewController?
  
  let locationManager  = CLLocationManager()
  
  private(set) var currentRoute : Route?
  
  enum RecordingState
  {
    case Idle(Bool)     // Authorized
    case Inserting(Int) // insertion index (0 = new start point)
    case Editing(Int)   // editting index
  }
  
  private(set) var state = RecordingState.Idle(false)
  
  private override init()
  {
    super.init()
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
  }
  
  
  // MARK: - Delegate methods
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
  {
    print("DC: Authorization Changed: \(status.rawValue)")
  }
  
}
