//
//  DataController.swift
//  truCourse
//
//  Created by Mike Mayer on 3/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class DataController : NSObject, CLLocationManagerDelegate
{
  @IBOutlet var dataViewController : DataViewController?
  
  let locationManager = CLLocationManager()
  
  private(set) var trackingEnabled    = true   // user sets this via toolbar
  private(set) var trackingAuthorized = false  // phone security settings
  
  private let routes = Routes()
  private var insertionPoint : InsertionPoint?
  
  private(set) var state : AppState = .Uninitialized
  
  private(set) var currentLocation  : CLLocation?
  private      var lastRecordedPost : CLLocation?
  
  let hasCompass = CLLocationManager.headingAvailable()
  
  private var mostRecentLocation : CLLocationCoordinate2D
  {
    let loc = currentLocation ?? locationManager.location
    let coord = loc?.coordinate ?? CLLocationCoordinate2D(latitude:  CLLocationDegrees(39,9,8),
                                                          longitude: CLLocationDegrees(-77,12,60))
    return coord
  }
  
  var okToRecord : Bool
  {
    if lastRecordedPost == nil { return true  }
    if currentLocation  == nil { return false }

    let threshold = Options.shared.minPostSeparation
    let distance  = currentLocation!.distance(from: lastRecordedPost!)
        
    return distance > threshold
  }
  
  var locked : Bool
  {
    get { return routes.working.locked   }
    set { routes.working.locked = locked }
  }
  
  var canShare : Bool
  {
    return routes.working.isEmpty == false
  }
  
  var canSave : Bool
  {
    return routes.working.isEmpty == false && routes.working.dirty == false
  }
  
  var canUndo : Bool
  {
    return routes.working.insertionHistory.isEmpty == false
  }
  
  // MARK: - Options
  
  func updateOptions()
  {
    locationManager.desiredAccuracy = Options.shared.locationAccuracy
    locationManager.distanceFilter  = Options.shared.locationFilter
  }
  
  // MARK: - App State
  
  func updateState(_ transition:AppStateTransition)
  {
    switch transition
    {
    case .Start:
      print("Transition = start")
      switch self.state
      {
      case .Uninitialized:
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        lastRecordedPost = nil
        updateState(.Authorization(status))
      default:
        print("DC start transition sent multiple times")
      }
      
    case .Authorization(let status):
      print("Transition = authorization(\(status))")
      if status == .authorizedAlways || status == .authorizedWhenInUse
      {
        if !trackingAuthorized
        {
          let currentRoute   = routes.working!
          
          updateTrackingState(authorized: true, enabled: nil)
          
          if trackingEnabled == false    { state = .Paused    }
          else if currentRoute.locked    { state = .Idle      }
          else if insertionPoint != nil  { state = .Inserting }
          else if currentRoute.isEmpty   { state = .Inserting }
          else                           { state = .Idle      }
        }
        
        if routes.working.declination == nil && hasCompass
        {
          locationManager.startUpdatingHeading()
        }
      }
      else
      {
        state = .Disabled
      }
      
    case .Enabled(let userEnabled):
      print("Transition = enabled(\(userEnabled))")
      if userEnabled { state = .Idle   }
      else           { state = .Paused }
      
    case .Insert(let index):
      print("Transition = insert(\(index))")
      
      if index != nil
      {
        insertionPoint?.candidate.unlink()
        
        guard routes.working.head != nil else
        { fatalError("Non-nil waypoint index without a working head") }
        
        if index == 0
        {
          insertionPoint = InsertionPoint( self.mostRecentLocation, before: routes.working.head! )
        }
        else if let wp = routes.working.head!.find(index: index!)
        {
          insertionPoint = InsertionPoint( self.mostRecentLocation, after: wp)
        }
        else
        {
          fatalError("Could not find waypoint \(index)")
        }
      }
      state = .Inserting
      
    case .Cancel:
      print("Transition = cancel");
      
      switch state
      {
      case .Inserting(_):
        state = .Idle
      case .Editing(_):
        if insertionPoint == nil { state = .Idle }
        else                     { state = .Inserting }
      default:
        fatalError("Pause button should not be visible unless in .Insert or .Edit state")
      }
      
    default:
      print("Transition = ???")
      print("DC need to implment transition \(transition)")
    }
    
    switch state
    {
    case .Uninitialized:
      print("State = uninitialized")
      break
      
    case .Disabled:
      print("State = disabled")
      updateTrackingState(authorized:false, enabled:nil)
  
    case .Paused:
      print("State = paused")
      updateTrackingState(authorized:true, enabled:false)
      insertionPoint?.unlink()
      insertionPoint  = nil
      dataViewController?.currentView.updateCandidate(nil)

    case .Idle:
      print("State = idle")
      updateTrackingState(authorized: true, enabled: true)
      insertionPoint?.unlink()
      insertionPoint  = nil
      dataViewController?.currentView.updateCandidate(nil)
  
    case .Inserting:
      print("State = inserting")
      updateTrackingState(authorized: true, enabled: true)
      locked = false

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
      dataViewController?.currentView.updateCandidate(insertionPoint?.candidate)
  
    case .Editing:
      print("State = editing")
      updateTrackingState(authorized: true, enabled: true)
      locked = false
    }
    
    dataViewController?.applyState()
    
    print("insertion = \(insertionPoint)")
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
      locationManager.startUpdatingLocation()
    }
    else
    {
      locationManager.stopUpdatingLocation()
    }
  }
  
  // MARK: - Data methods
  
  func popupActions(for index:Int) -> [UIAlertAction]
  {
    var insertAfter = true
    var insertBefore = true
    var update = true
    var delete = true
    
    if insertionPoint?.after?.index  == index { insertAfter = false }
    if insertionPoint?.before?.index == index { insertBefore = false }
    
    var actions = [UIAlertAction]()
    
    if insertAfter
    {
      let insertion = { self.updateState(.Insert(index)) }
      actions.append( UIAlertAction(title: "Insert New Post \(index+1)",
                                    style: .default,
                                    handler: { _ in self.dataViewController?.confirmUnlock(insertion) } ) )
    }
    
    if insertBefore
    {
      let insertion = { self.updateState(.Insert(index-1)) }
      actions.append( UIAlertAction(title: "Insert New Post \(index)",
                                    style: .default,
                                    handler: { _ in self.dataViewController?.confirmUnlock(insertion) } ) )
    }
    
    if update
    {
      actions.append( UIAlertAction(title: "Update Existing Post \(index)",
                                    style: .default,
                                    handler: { (action:UIAlertAction) in print("update post \(index)") } ) )
    }
    
    if delete
    {
      actions.append( UIAlertAction(title: "Delete Post \(index)",
                                    style: .destructive,
                                    handler: { (action:UIAlertAction) in print("delete post \(index)") } ) )
    }
  
    return actions
  }
  
  func record()
  {
    switch state
    {
    case .Inserting(_):
      let cand = insertionPoint!.candidate
      routes.working.insert(insertionPoint!)
      insertionPoint = InsertionPoint(self.mostRecentLocation, after:cand)
      dataViewController?.currentView.updateRoute(routes.working)

      lastRecordedPost = currentLocation
      dataViewController?.applyState()
      
    case .Editing(let index):
      print("Need to handle record during editing")
    default:
      fatalError("Recording should only be called in insert or edit mode")
    }
  }
  
  func undoRecord()
  {
    let doUndo = {
      self.routes.working.undoInsertion(update:self.insertionPoint)
      self.dataViewController?.currentView.updateRoute(self.routes.working)
      
      self.lastRecordedPost = nil
      self.dataViewController?.applyState()
      
      if self.routes.working.head == nil { self.insertionPoint = nil }
    }
    
    if dataViewController == nil
    {
      doUndo()
    }
    else
    {
      let post = routes.working.insertionHistory.last?.index
      var title = "Remove post"
      if post != nil { title = "\(title) \(post!)" }
      let alert = UIAlertController(title: title,
                                    message: "Please confirm deleting the most recent post (you will not be able to undo changes)",
                                    preferredStyle: .alert)
      
      alert.addAction( UIAlertAction(title: "OK", style: .destructive) { (_:UIAlertAction) in doUndo() } )
      alert.addAction( UIAlertAction(title: "Cancel", style: .cancel) )
      
      dataViewController!.present(alert, animated: true)
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
    
    if let cand = insertionPoint?.candidate
    {
      cand.location = currentLocation!.coordinate
      dataViewController?.currentView.updateCandidate(cand)
    }
    
    dataViewController?.handleLocationUpdate()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
  {
    if routes.working.declination == nil
    {
      routes.working.setDeclination(newHeading)
      Options.shared.declination = routes.working.declination
    }
    locationManager.stopUpdatingHeading()
  }
}
