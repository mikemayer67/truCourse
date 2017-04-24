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
  
  private(set) var state : AppState = .Uninitialized
  
  private(set) var candidatePost  : Waypoint?
  {
    willSet
    {
      if candidatePost?.isCandidate == true { candidatePost!.unlink() }
    }
  }
  
  private(set) var insertionIndex : Int?
  
  private(set) var currentLocation  : CLLocation?
  private      var lastRecordedPost : CLLocation?
  
  private(set) var undoStack = [UndoableAction]()
  private(set) var redoStack = [UndoableAction]()
  
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
    return undoStack.isEmpty == false
  }
  
  var canRedo : Bool
  {
    return redoStack.isEmpty == false
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
        return
      default:
        print("DC start transition sent multiple times")
      }
      
    case .Authorization(let status):
      print("Transition = \(transition.string)")
      if status == .authorizedAlways || status == .authorizedWhenInUse
      {
        if !trackingAuthorized
        {
          let currentRoute   = routes.working!
          
          updateTrackingState(authorized: true, enabled: nil)
          
          if trackingEnabled == false    { state = .Paused    }
          else if currentRoute.locked    { state = .Idle      }
          else if insertionIndex != nil  { state = .Inserting }
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
      
      insertionIndex = index
      candidatePost = nil
      state = .Inserting
      
    case .Cancel:
      print("Transition = cancel");
      
      switch state
      {
      case .Inserting(_):
        state = .Idle
      case .Editing(_):
        if insertionIndex == nil { state = .Idle }
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
      candidatePost = nil
      dataViewController?.currentView.update(candidate:nil)

    case .Idle:
      print("State = idle")
      updateTrackingState(authorized: true, enabled: true)
      candidatePost = nil
      dataViewController?.currentView.update(candidate:nil)
  
    case .Inserting:
      print("State = inserting")
      updateTrackingState(authorized: true, enabled: true)
      locked = false
      
      candidatePost = Waypoint(self.mostRecentLocation)

      let n = routes.working.count
      if insertionIndex == nil { insertionIndex = n+1 }
      
      if routes.working.head != nil
      {
        if insertionIndex! == 1
        {
          candidatePost?.insert(before: routes.working.head!, as: .Candidate)
        }
        else
        {
          let ref_wp = routes.working.find(post: insertionIndex! - 1)
          if ref_wp == nil { fatalError("Cannot insert post #\(insertionIndex!)... route only has \(n) posts") }
          candidatePost?.insert(after: ref_wp!, as: .Candidate)
        }
      }
      
      dataViewController?.currentView.update(candidate:candidatePost)
  
    case .Editing:
      print("State = editing")
      updateTrackingState(authorized: true, enabled: true)
      locked = false
    }
    
    dataViewController?.applyState()
    
    print("insertion = \(insertionIndex)")
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
  
  func update(route:Route)
  {
    dataViewController?.updateRoute(route:route)
  }
  
  // MARK: - Data methods
  
  func popupActions(for index:Int) -> [UIAlertAction]
  {
    var insertAfter  = true
    var insertBefore = true
    var renumber     = true
    var update       = true
    var delete       = true
    
    var actions = [UIAlertAction]()
    
    if insertBefore
    {
      let insertion = { self.updateState(.Insert(index-1)) }
      actions.append( UIAlertAction(title: "Insert new post before it",
                                    style: .default,
                                    handler: { _ in self.dataViewController?.confirmUnlock(insertion) } ) )
    }
    
    if insertAfter
    {
      let insertion = { self.updateState(.Insert(index)) }
      actions.append( UIAlertAction(title: "Insert new post after it",
                                    style: .default,
                                    handler: { _ in self.dataViewController?.confirmUnlock(insertion) } ) )
    }
    
    if renumber
    {
      actions.append( UIAlertAction(title: "Renumber it...",
                                    style: .default,
                                    handler: { (action:UIAlertAction) in print ("renumber post \(index)") } ) )
    }
    
    if update
    {
      actions.append( UIAlertAction(title: "Relocate it",
                                    style: .default,
                                    handler: { (action:UIAlertAction) in print("update post \(index)") } ) )
    }
    
    if delete
    {
      actions.append( UIAlertAction(title: "Delete it...",
                                    style: .destructive,
                                    handler: { (action:UIAlertAction) in print("delete post \(index)") } ) )
    }
  
    return actions
  }
  
  func record()
  {
    switch state
    {
    case .Inserting:
      let cand  = candidatePost!
      let index = insertionIndex!
      
      routes.working.commit(cand, at:index)
      
      candidatePost  = Waypoint(self.mostRecentLocation)
      candidatePost!.insert(after: cand, as: .Candidate)
      insertionIndex = index + 1
      
      redoStack.removeAll()
      undoStack.append( InsertionAction(self, post:index, at:cand.location, on:routes.working) )
        
      dataViewController?.currentView.update(route:routes.working)

      lastRecordedPost = currentLocation
      dataViewController?.applyState()
      
    case .Editing(let index):
      print("Need to handle record during editing")
    default:
      fatalError("Recording should only be called in insert or edit mode")
    }
  }
  
  // MARK: - Undo/Redo actions
  
  func undoLastAction()
  {
    if undoStack.isEmpty { return }
    
    let action = undoStack.removeLast()
    
    redoStack.append(action)
    
    action.undo()
  }
  
  func redoLastAction()
  {
    if redoStack.isEmpty { return }
    
    let action = redoStack.removeLast()
    
    undoStack.append(action)
    
    action.redo()
  }
  
  func undoInsertion(_ action:InsertionAction)
  {
    let doUndo =
    {
      action.route.remove(post: action.post)
      
      self.dataViewController?.currentView.update(route:self.routes.working)
      
      self.lastRecordedPost = nil
      self.dataViewController?.applyState()
      
      self.insertionIndex = action.post
    }
    
    if dataViewController == nil
    {
      doUndo()
    }
    else
    {
      let alert = UIAlertController(title: "Remove post \(action.post)",
                                    message: "Confirm deletion",
                                    preferredStyle: .alert)
      
      alert.addAction( UIAlertAction(title: "OK", style: .destructive) { (_:UIAlertAction) in doUndo() } )
      alert.addAction( UIAlertAction(title: "Cancel", style: .cancel) )
      
      dataViewController!.present(alert, animated: true)
    }
  }
  
  func redoInsertion(_ action:InsertionAction)
  {
    
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
    
    if let cand = candidatePost
    {
      cand.location = currentLocation!.coordinate
      dataViewController?.currentView.update(candidate:cand)
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
