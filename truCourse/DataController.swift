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

class DataController : NSObject, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, RenumberViewDelegate
{
  @IBOutlet var dataViewController : DataViewController!
  
  let locationManager = CLLocationManager()
  
  private(set) var trackingEnabled    = true   // user sets this via toolbar
  private(set) var trackingAuthorized = false  // phone security settings
  
  private let routes = Routes()
  private var route : Route!
  
  override init()
  {
    route = routes.working
  }
  
  private(set) var state : AppState = .Uninitialized
  
  private(set) var candidatePost  : Waypoint?
  {
    willSet
    {
      if candidatePost?.isCandidate == true { candidatePost!.unlink() }
    }
  }
  
  private(set) var insertionIndex : Int?
  private(set) var renumberIndex  : Int?
  
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
    get { return route.locked   }
    set { route.locked = locked }
  }
  
  var canShare : Bool
  {
    return route.isEmpty == false
  }
  
  var canSave : Bool
  {
    return route.isEmpty == false && route.dirty == false
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
      if status == .authorizedAlways || status == .authorizedWhenInUse
      {
        if !trackingAuthorized
        {
          updateTrackingState(authorized: true, enabled: nil)
          
          if trackingEnabled == false    { state = .Paused    }
          else if route.locked           { state = .Idle      }
          else if insertionIndex != nil  { state = .Inserting }
          else if route.isEmpty          { state = .Inserting }
          else                           { state = .Idle      }
        }
        
        if route.declination == nil && hasCompass
        {
          locationManager.startUpdatingHeading()
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
      if index != nil { insertionIndex = index }
      
      candidatePost = nil
      state = .Inserting
      
    case .Pause:
      switch state
      {
      case .Inserting(_):
        state = .Idle
      default:
        fatalError("Pause button should not be visible unless in .Insert or .Edit state")
      }
    }
    
    switch state
    {
    case .Uninitialized:
      break
      
    case .Disabled:
      updateTrackingState(authorized:false, enabled:nil)
  
    case .Paused:
      updateTrackingState(authorized:true, enabled:false)
      candidatePost = nil
      dataViewController.removeCandidate()

    case .Idle:
      updateTrackingState(authorized: true, enabled: true)
      candidatePost = nil
      dataViewController.removeCandidate()
  
    case .Inserting:
      updateTrackingState(authorized: true, enabled: true)
      locked = false
      
      candidatePost = Waypoint(self.mostRecentLocation)

      let n = route.count
      if insertionIndex == nil { insertionIndex = n+1 }
      
      if route.head != nil
      {
        if insertionIndex! == 1
        {
          candidatePost?.insert(before: route.head!, as: .Candidate)
        }
        else
        {
          let ref_wp = route.find(post: insertionIndex! - 1)
          if ref_wp == nil { fatalError("Cannot insert post #\(insertionIndex!)... route only has \(n) posts") }
          candidatePost?.insert(after: ref_wp!, as: .Candidate)
        }
      }
      
      dataViewController.updateCandidate(candidatePost!)
    }
    
    dataViewController.applyState()
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
  
  func popupActions(for post:Int) -> [UIAlertAction]?
  {
    let dvc = self.dataViewController!
    
    var actions = [UIAlertAction]()
    
    if post == 1
    {
      if route.count > 2
      {
        actions.append(
          UIAlertAction(title:"reverse route", style:.default, handler:
            { (_:UIAlertAction)->Void in
              dvc.confirmAction(type: .ReverseRoute, action:
                {
                  let action = ReverseRouteAction(self)
                  if action.redo() { UndoManager.shared.add(action) }
                } )
            } ) )
      }
      
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
            dvc.confirmAction(type: .NewStart(post), action:
              {
                let action = NewStartAction(self, post:post)
                if self.redo(newStart: action) { UndoManager.shared.add(action) }
              } )
          } ) )
    }
    
    if insertionIndex != post + 1
    {
      actions.append(
        UIAlertAction(title: "add new post \(post+1)", style:.default, handler:
          { (_:UIAlertAction)->Void in
            dvc.confirmAction(type:.Insertion, action: { self.updateState(.Insert(post+1)) } )
          } ) )
    }
    
    actions.append(
      UIAlertAction(title: "move post to current location", style: .default, handler:
        { (_:UIAlertAction)->Void in
          let newLocation = self.mostRecentLocation
          dvc.confirmAction(type: .MovePost(post), action:
            {
              guard let oldLocation = self.route.find(post:post)?.location else { return }
              let   action = MovePostAction(self, post: post, from: oldLocation, to: newLocation)
              if action.redo() { UndoManager.shared.add(action) }
            } )
      } ) )
    
    if route.count > 2
    {
      actions.append(
        UIAlertAction(title: "renumber post \(post)...", style: .default, handler:
          { (_:UIAlertAction)->Void in
            dvc.confirmAction(type:.RenumberPost(post), action: { self.renumber(post:post) } )
        } ) )
    }
    
    actions.append(
      UIAlertAction(title: "delete post \(post)...", style:.destructive, handler:
        { (_:UIAlertAction)->Void in
          dvc.confirmAction(type:.Deletion(post), action:
            {
              let location = self.route.find(post:post)!.location
              let action = DeletionAction(self, post:post, at:location)
              if self.redo(deletion: action) { UndoManager.shared.add(action) }
            } )
        } ) )
  
    return actions
  }
  
  func record()
  {
    let cand  = candidatePost!
    let index = insertionIndex!
    
    route.commit(cand, at:index)
    
    candidatePost  = Waypoint(self.mostRecentLocation)
    candidatePost!.insert(after: cand, as: .Candidate)
    insertionIndex = index + 1
    
    UndoManager.shared.add( InsertionAction(self, post:index, at:cand.location) )
    
    lastRecordedPost = currentLocation
    dataViewController.updateRoute(route)
  }
  
  func renumber(post:Int)
  {
    let rc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RenumberViewController") as! RenumberViewController
    
    rc.delegate = self
    rc.modalPresentationStyle = .overCurrentContext
    rc.transitioningDelegate  = rc
    rc.modalPresentationCapturesStatusBarAppearance = true
    rc.setNeedsStatusBarAppearanceUpdate()
    dataViewController.definesPresentationContext = true
    
    renumberIndex = post
    
    dataViewController.parent!.present(rc, animated: true)
  }
  
  // MARK: - Undo/Redo actions
  
  @discardableResult
  func undo(insertion:InsertionAction) -> Bool
  {
    dataViewController.confirmAction(
      type: .Deletion(insertion.post),
      action: {
        self.route.remove(post: insertion.post)
        self.dataViewController.updateRoute(self.route)
        self.lastRecordedPost = nil
        self.dataViewController.applyState()
        self.insertionIndex = insertion.post
      },
      failure: {
        UndoManager.shared.cancel(undo:insertion)
      }
    )
    
    return true
  }
  
  @discardableResult
  func redo(insertion:InsertionAction) -> Bool
  {
    route.insert(post: insertion.post, at: insertion.location)
    
    dataViewController.updateRoute(route)
    
    lastRecordedPost = nil
    dataViewController.applyState()
    insertionIndex = insertion.post + 1
    
    return true
  }
  
  @discardableResult
  func undo(deletion:DeletionAction) -> Bool
  {
    route.insert(post: deletion.post, at: deletion.location)
    
    if insertionIndex != nil,
      insertionIndex! >= deletion.post
    {
      insertionIndex = insertionIndex! + 1
    }
    
    dataViewController.updateRoute(route)
    
    return true
  }
  
  @discardableResult
  func redo(deletion:DeletionAction) -> Bool
  {
    route.remove(post:deletion.post)
    
    if insertionIndex != nil
    {
      if insertionIndex! > deletion.post { insertionIndex = insertionIndex! - 1 }
    }
    
    dataViewController.updateRoute(route)
    
    return true
  }
  
  @discardableResult
  func undo(newStart:NewStartAction) -> Bool
  {
    let post    = newStart.post
    let n       = route.count
    let oldPost =  ( n + 1 - post)%n + 1
    
    let rval = route.restart(at: oldPost)
  
    if rval
    {
      if insertionIndex != nil
      {
        insertionIndex = (insertionIndex! - oldPost + n ) % n + 1
      }
      
      dataViewController.updateRoute(route)
    }
    return rval
  }
  
  @discardableResult
  func redo(newStart:NewStartAction) -> Bool
  {
    let post  = newStart.post
    let n     = route.count
    
    guard route.restart(at: post) else { return false }
    
    if insertionIndex != nil
    {
      insertionIndex = (insertionIndex! - post + n ) % n + 1
    }
    
    dataViewController.updateRoute(route)
    
    return true
  }
  
  @discardableResult
  func undo(reverseRoute action:ReverseRouteAction) -> Bool
  {
    return _reverseRoute()
  }
  
  @discardableResult
  func redo(reverseRoute action:ReverseRouteAction) -> Bool
  {
    return _reverseRoute()
  }
  
  private func _reverseRoute() -> Bool
  {
    guard route.reverse() else { return false }
    
    if insertionIndex != nil
    {
      let n = route.count
      insertionIndex = (n+3) - insertionIndex!
    }
    
    dataViewController.updateRoute(route)
    
    return true
  }
  
  
  @discardableResult
  func undo(renumberPost action:RenumberPostAction)->Bool
  {
    return _do(renumberPost:action.newPost, as:action.oldPost)
  }
  
  @discardableResult
  func redo(renumberPost action:RenumberPostAction)->Bool
  {
    return _do(renumberPost:action.oldPost, as:action.newPost)
  }
  
  func _do(renumberPost oldPost:Int, as newPost:Int) -> Bool
  {
    let oldState = self.state
    
    candidatePost = nil;
    
    guard route.renumber(post:oldPost, as:newPost) else { return false }
    
    switch oldState
    {
    case .Inserting:
      updateState(.Insert(insertionIndex))
    default:
      break
    }
        
    dataViewController.updateRoute(route)
    
    return true
  }
  
  @discardableResult
  func undo(movePost action:MovePostAction)->Bool
  {
    return _do(move:action.post, to:action.oldLocation)
  }
  
  @discardableResult
  func redo(movePost action:MovePostAction)->Bool
  {
    return _do(move:action.post, to:action.newLocation)
  }
  
  func _do(move post:Int, to location:CLLocationCoordinate2D) -> Bool
  {
    guard let wp = route.find(post: post) else { return false }
    
    wp.location = location
    dataViewController.updateRoute(route)
    
    return true
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
      dataViewController.updateCandidate(cand)
    }
    
    dataViewController.handleLocationUpdate()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
  {
    if route.declination == nil
    {
      route.setDeclination(newHeading)
      Options.shared.declination = route.declination
    }
    locationManager.stopUpdatingHeading()
  }
  
  // MARK: - Renumber Picker delegate methods
  
  func title(for view: RenumberViewController) -> String?
  {
    guard let post = renumberIndex else { return nil }
    return "Renumber Post \(post) as:"
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
  {
    return route.count - 1
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int
  {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
  {
    let post = (row+1 < renumberIndex! ? row+1 : row+2)
    return "Post \(post)"
  }
  
  func renumberView(_ view: RenumberViewController, didSelect row: Int)
  {
    let oldPost = renumberIndex!
    let newPost = (row+1 < oldPost ? row+1 : row+2)
    
    let action = RenumberPostAction(self, from:oldPost, to:newPost)
    
    if action.redo() { UndoManager.shared.add(action) }
  }
}
