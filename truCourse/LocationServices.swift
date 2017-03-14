//
//  LocationServices.swift
//  truCourse
//
//  Created by Mike Mayer on 3/10/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServicesDelegate
{
  func locationServices(enabled:Bool)->Void
}

class LocationServices : NSObject, CLLocationManagerDelegate
{
  let manager    = CLLocationManager()
  let hasCompass = CLLocationManager.headingAvailable()
  
  var delegate : LocationServicesDelegate?
  
  // MARK: - Singleton methods
  
  private static var _instance : LocationServices?
  static var shared : LocationServices
  {
    if _instance == nil { _instance = LocationServices() }
    return _instance!
  }
  
  override init()
  {
    super.init()
    manager.delegate = self
  }
  
  // MARK: - Authorization methods
  
  func requestAuthorization()
  {
    manager.requestWhenInUseAuthorization()
  }
  
  // MARK: - Delegate methods
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
  {
    delegate?.locationServices(enabled: status == .authorizedWhenInUse || status == .authorizedAlways)
  }
}
