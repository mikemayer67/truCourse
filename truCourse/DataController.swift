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
  
  private(set) var trackingEnabled    = true   // user sets this via toolbar
  private(set) var trackingAuthorized = false  // phone security settings
  
  let routes = Routes()
  
  private(set) var currentRoute   : Route?
  private(set) var insertionPoint : Waypoint?

  private(set) var state : AppState = .Uninitialized
  
  //  private override init()
  //  {
  //    super.init()
  //    locationManager.delegate = self
  //    locationManager.requestWhenInUseAuthorization()
  //  }
  
  func updateOptions()
  {
    updateTrackingOptions()
  }
  
  func updateTrackingOptions()
  {
    let options = dataViewController?.options
    locationManager.desiredAccuracy = options?.locationAccuracy ??  5.0
    locationManager.distanceFilter  = options?.locationFilter   ?? 10.0
  }
  
  // MARK: - App State
  
  func updateState(_ transition:AppStateTransition)
  {
    switch transition
    {
    case .Start:
      switch self.state
      {
      case .Uninitialized:
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        updateState(.Authorization(status))
      default:
        print("DC start transition sent multiple times")
      }
      
    case .Authorization(let status):
      if status == .authorizedAlways || status == .authorizedWhenInUse
      {
        if !trackingAuthorized
        {
          trackingAuthorized = true
          if trackingEnabled
          {
            state = .Paused
          }
          else if currentRoute == nil
          {
            state = .Idle
          }
          else if currentRoute!.isEmpty
          {
            state = .Inserting(currentRoute!.count)
          }
          else if insertionPoint != nil,
            let index = insertionPoint!.index
          {
            state = .Inserting(index)
          }
          else
          {
            state = .Idle
          }
        }
      }
      else
      {
        state = .Disabled
      }
      
    default:
      print("DC need to implment transition \(transition)")
    }
    
    
    switch state
    {
    case .Uninitialized:
      break
      
    case .Disabled:
      updateTrackingState(authorized:false, enabled:nil)
  
    case .Paused:
      updateTrackingState(authorized:true, enabled:false)
      insertionPoint  = nil

    case .Idle:
      updateTrackingState(authorized: true, enabled: true)
      insertionPoint  = nil

  
    case .Inserting(let index):
      updateTrackingState(authorized: true, enabled: true)
      currentRoute!.locked = false
      insertionPoint = currentRoute![index]

  
    case .Editing:
      updateTrackingState(authorized: true, enabled: true)
      currentRoute!.locked = false
    }
    
    dataViewController?.updateState(state)
  }
  
  func updateTrackingState(authorized:Bool?, enabled:Bool?)
  {
    guard authorized != nil || enabled != nil else
    { fatalError("Must specify either authorized or enabled status") }
    
    var changed = false
    
    if authorized != nil && authorized! != trackingAuthorized
    {
      changed = true
      trackingAuthorized = authorized!
    }
    if enabled != nil && enabled != trackingEnabled
    {
      changed = true
      trackingEnabled = enabled!
    }
    
    if !changed { return }
    
    if trackingAuthorized && trackingEnabled
    {
      updateTrackingOptions()
      locationManager.startUpdatingLocation()
    }
    else
    {
      locationManager.stopUpdatingLocation()
    }
  }
  
  
  // MARK: - Location Manager Delegate
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
  {
    updateState(.Authorization(status))
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
  {
    for loc in locations
    {
      print("DC new location: \(loc.coordinate.longitude) \(loc.coordinate.latitude)")
    }
  }
}
