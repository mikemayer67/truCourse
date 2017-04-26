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
  @IBOutlet var dataViewController : DataViewController!
  
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
      
      if index != nil { insertionIndex = index }
      
      candidatePost = nil
      state = .Inserting
      
    case .Pause:
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
      dataViewController.currentView.update(candidate:nil)

    case .Idle:
      print("State = idle")
      updateTrackingState(authorized: true, enabled: true)
      candidatePost = nil
      dataViewController.currentView.update(candidate:nil)
  
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
      
      dataViewController.currentView.update(candidate:candidatePost)
  
    case .Editing:
      print("State = editing")
      updateTrackingState(authorized: true, enabled: true)
      locked = false
    }
    
    dataViewController.applyState()
    
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
    dataViewController.updateRoute(route:route)
  }
  
  // MARK: - Data methods
  
  func popupActions(for post:Int) -> [UIAlertAction]?
  {
    let dvc = self.dataViewController!
    
    var actions = [UIAlertAction]()
    
    if post == 1
    {
      actions.append(
        UIAlertAction(title:"reverse route", style:.default, handler:
          { (_:UIAlertAction)->Void in
            dvc.confirmAction(type: .ReverseRoute, action: { self.reverseRoute() } )
          } ) )
      
      actions.append(
        UIAlertAction(title: "add new first post", style:.default, handler:
          { (_:UIAlertAction)->Void in
            dvc.confirmAction(type:.Insertion, action: { self.updateState(.Insert(post)) } )
          } ) )
    }
    else
    {
      actions.append(
        UIAlertAction(title: "make this first post", style:.default, handler:
          { (_:UIAlertAction)->Void in
            dvc.confirmAction(type: .NewStart(post), action: { self.restart(at:post) } )
          } ) )
    }
    
    actions.append(
      UIAlertAction(title: "add new post \(post+1)", style:.default, handler:
        { (_:UIAlertAction)->Void in
          dvc.confirmAction(type:.Insertion, action: { self.updateState(.Insert(post+1)) } )
        } ) )
    
    actions.append(
      UIAlertAction(title: "renumber post \(post)...", style: .default, handler:
        { (_:UIAlertAction)->Void in
          print ("renumber post \(post)")
        } ) )
    
    actions.append(
      UIAlertAction(title: "move post \(post)", style: .default, handler:
        { (_:UIAlertAction)->Void in
          print("update post \(post)")
        } ) )
    
    actions.append(
      UIAlertAction(title: "delete post \(post)...", style:.destructive, handler:
        { (_:UIAlertAction)->Void in
          dvc.confirmAction(type:.Deletion(post), action: { self.delete(post:post) } )
        } ) )
  
    return actions
  }
  
  func record()
  {
    switch state
    {
    case .Inserting:
      let cand  = candidatePost!
      let index = insertionIndex!
      
      let route = routes.working!
      
      route.commit(cand, at:index)
      
      candidatePost  = Waypoint(self.mostRecentLocation)
      candidatePost!.insert(after: cand, as: .Candidate)
      insertionIndex = index + 1

      UndoManager.shared.add( InsertionAction(self, post:index, at:cand.location, on:route) )
        
      dataViewController.currentView.update(route:route)

      lastRecordedPost = currentLocation
      dataViewController.applyState()
      
    case .Editing(let index):
      print("Need to handle record during editing")
    default:
      fatalError("Recording should only be called in insert or edit mode")
    }
  }
  
  func delete(post:Int)
  {
    let route = routes.working!
    let wp    = route.find(post: post)!
    
    UndoManager.shared.add( DeletionAction(self, post: post, at: wp.location, on: route) )
    
    route.remove(post: post)
    
    if insertionIndex != nil
    {
      if insertionIndex! > post { insertionIndex = insertionIndex! - 1 }
    }
    
    dataViewController.currentView.update(route: route)
    
    lastRecordedPost = nil
    dataViewController.applyState()

  }
  
  func reverseRoute()
  {
    print("reverse route")
  }
  
  func restart(at post:Int)
  {
    print("restart at: \(post)")
    
    let route = routes.working!
    
    if route.restart(at: post)
    {
      if insertionIndex != nil
      {
        let n = route.count
        insertionIndex = ( insertionIndex! - post + n ) % n + 1
      }
      
      UndoManager.shared.add(NewStartAction(self, post:post, on:route) )
      dataViewController.currentView.update(route: route)
      
      lastRecordedPost = nil
      dataViewController.applyState()
    }
  }
  
  // MARK: - Undo/Redo actions
  
  func undo(insertion:InsertionAction)
  {
    dataViewController.confirmAction(
      type: .Deletion(insertion.post),
      action: {
        let route = insertion.route
        route.remove(post: insertion.post)
        self.dataViewController.currentView.update(route:route)
        self.lastRecordedPost = nil
        self.dataViewController.applyState()
        self.insertionIndex = insertion.post
      },
      failure: {
        UndoManager.shared.cancel(undo:insertion)
      }
    )
  }
  
  func redo(insertion:InsertionAction)
  {
    let route = insertion.route
    
    route.insert(post: insertion.post, at: insertion.location)
    
    dataViewController.currentView.update(route:route)
    
    lastRecordedPost = nil
    dataViewController.applyState()
    insertionIndex = insertion.post + 1
  }
  
  func undo(deletion:DeletionAction)
  {
    let route = deletion.route
    
    route.insert(post: deletion.post, at: deletion.location)
    
    if insertionIndex != nil,
      insertionIndex! >= deletion.post
    {
      insertionIndex = insertionIndex! + 1
    }
    
    dataViewController.currentView.update(route:route)
    
    lastRecordedPost = nil
    dataViewController.applyState()
  }
  
  func redo(deletion:DeletionAction)
  {
    let route = deletion.route
    
    route.remove(post:deletion.post)
    
    if insertionIndex != nil
    {
      if insertionIndex! > deletion.post { insertionIndex = insertionIndex! - 1 }
    }
    
    dataViewController.currentView.update(route: route)
    
    lastRecordedPost = nil
    dataViewController.applyState()
  }
  
  func undo(newStart:NewStartAction)
  {    
    let post  = newStart.post
    let route = newStart.route
    
    let n       = route.count
    let oldPost =  ( n + 1 - post)%n + 1
    
    if( route.restart(at: oldPost) )
    {
      if insertionIndex != nil
      {
        insertionIndex = (insertionIndex! - oldPost + n ) % n + 1
      }
      
      dataViewController.currentView.update(route: route)
      dataViewController.applyState()
    }
  }
  
  func redo(newStart:NewStartAction)
  {
    let post  = newStart.post
    let route = newStart.route
    
    let n       = route.count
    
    if( route.restart(at: post) )
    {
      if insertionIndex != nil
      {
        insertionIndex = (insertionIndex! - post + n ) % n + 1
      }
      
      dataViewController.currentView.update(route: route)
      dataViewController.applyState()
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
    
    if let cand = candidatePost
    {
      cand.location = currentLocation!.coordinate
      dataViewController.currentView.update(candidate:cand)
    }
    
    dataViewController.handleLocationUpdate()
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
