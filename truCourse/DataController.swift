//
//  DataController.swift
//  truCourse
//
//  Created by Mike Mayer on 3/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import CoreLocation

func dms(_ deg:Int, _ min:Int = 0, _ sec:Int = 0) -> Double
{
  let ms = Double(min) + Double(sec)/60.0
  return ( deg < 0 ? Double(deg) - ms : Double(deg) + ms )
}


class DataController : NSObject, CLLocationManagerDelegate
{
  @IBOutlet var dataViewController : DataViewController?
  
  let locationManager = CLLocationManager()
  
  private(set) var trackingEnabled    = true   // user sets this via toolbar
  private(set) var trackingAuthorized = false  // phone security settings
  
  let routes = Routes()
  private var candidate      : Waypoint?
  private var insertionPoint : InsertionPoint?
  
  private(set) var state : AppState = .Uninitialized
  
  private(set) var currentLocation  : CLLocation?
  private      var lastRecordedPost : CLLocation?
  
  private var mostRecentLocation : CLLocationCoordinate2D
  {
    let loc = currentLocation ?? locationManager.location
    let coord = loc?.coordinate ?? CLLocationCoordinate2D(latitude: dms(39,9,8), longitude: dms(-77,12,60))
    return coord
  }
  
  var okToRecord : Bool
  {
    if lastRecordedPost == nil { return true  }
    if currentLocation  == nil { return false }

    let options   = dataViewController?.options
    let threshold = options?.minPostSeparation ?? 10.0
    let distance  = currentLocation!.distance(from: lastRecordedPost!)
    
    print("okToRecord(\(distance)>\(threshold)): \(distance>threshold)")
    
    return distance > threshold
  }
  
  // MARK: - Options
  
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
          let currentRoute   = routes.working!
          
          trackingAuthorized = true
          if trackingEnabled == false    { state = .Paused    }
          else if currentRoute.locked    { state = .Idle      }
          else if insertionPoint != nil  { state = .Inserting }
          else if currentRoute.isEmpty   { state = .Inserting }
          else                           { state = .Idle      }
        }
      }
      else
      {
        state = .Disabled
      }
      
    case .Enabled(let userEnabled):
      if userEnabled { state = .Idle   }
      else           { state = .Paused }
      
    case .Insert(let index):
      if index != nil
      {
        insertionPoint?.candidate.unlink()
        
        if index == 0 && routes.working.head != nil
        {
          insertionPoint = InsertionPoint( self.mostRecentLocation )
        }
        else
        {
          insertionPoint = InsertionPoint( self.mostRecentLocation, before: routes.working.head! )
        }
      }
      state = .Inserting
      
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
  
    case .Inserting:
      updateTrackingState(authorized: true, enabled: true)
      routes.working.locked = false

      if insertionPoint == nil
      {
        if routes.working.head != nil
        {
          insertionPoint = InsertionPoint(self.mostRecentLocation, after:routes.working.tail!)
        }
        else
        {
          insertionPoint = InsertionPoint(self.mostRecentLocation)
        }
      }
  
    case .Editing:
      updateTrackingState(authorized: true, enabled: true)
      routes.working.locked = false
    }
    
    dataViewController?.applyState()
  }
  
  func dropInsertionPoint()
  {
    if insertionPoint == nil { return }
    insertionPoint = nil
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
    if locations.isEmpty { return }
    
    currentLocation = locations[locations.endIndex-1]
    
    for loc in locations
    {
      print("DC new location: \(loc.coordinate.longitude) \(loc.coordinate.latitude)")
    }
    
    print("new Location: \(currentLocation)  okToRecord: \(self.okToRecord)")
    print("Add check to activate record button")
    
    //    dataViewController?.applyState()
  }
}
