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

private func dataPath(_ filename:String) -> URL
{
  do
  {
    let path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    return path.appendingPathComponent(filename)
  }
  catch
  {
    fatalError("Cannot create URL for \(filename)")
  }
}

class DataController : NSObject, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, RenumberViewDelegate, UIActivityItemSource, RouteInfoViewDelegate, RoutesViewControllerDelegate
{
  @IBOutlet var dataViewController     : DataViewController!
            var renumberViewController : RenumberViewController?
  
  let locationManager = CLLocationManager()
  
  static let routesDataFile = dataPath("routes.plist")
  static let workingDataFile = dataPath("working.plist")
  
  private(set) var trackingEnabled    = true   // user sets this via toolbar
  private(set) var trackingAuthorized = false  // phone security settings
  
  private(set) var route : WorkingRoute!
  
  override init()
  {
    Routes.shared = Routes(load:DataController.routesDataFile)
    self.route    = WorkingRoute(load:DataController.workingDataFile)
    
    if self.route.dirty == false { self.route = WorkingRoute() }
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
  private      var renumberIndex  : Int?
  
  private(set) var currentLocation  : CLLocation?
  private      var lastRecordedPost : CLLocation?
    
  private var mostRecentLocation : CLLocationCoordinate2D
  {
    let loc = currentLocation ?? locationManager.location
    let coord = loc?.coordinate ?? CLLocationCoordinate2D(latitude:  CLLocationDegrees(39,9,8),
                                                          longitude: CLLocationDegrees(-77,12,60))
    return coord
  }
  
  func getCurrentLocation() -> CLLocation?
  {
    return currentLocation ?? locationManager.location
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
    set { route.locked = newValue }
  }
  
  var canShare : Bool
  {
    return route.isEmpty == false
  }
  
  var canSave : Bool
  {
    if route.isEmpty   == true { return false }
    if route.dirty     == true { return true }
    if route.lastSaved == nil  { return true }
    return false
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
    let dvc = self.dataViewController!

    switch transition
    {
    case .Start:
      guard self.state == .Uninitialized else { fatalError("Cannot start app multiple times") }
      
      self.start()
      return
      
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
        
        self.updateDeclinationIfNeeded()
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
      dvc.removeCandidate()

    case .Idle:
      updateTrackingState(authorized: true, enabled: true)
      candidatePost = nil
      dvc.removeCandidate()
  
    case .Inserting:
      updateTrackingState(authorized: true, enabled: true)
      locked = false
      
      candidatePost = Waypoint(self.mostRecentLocation)

      let n = route.count
      if insertionIndex == nil { insertionIndex = n+1 }
      
      if route.head != nil
      {
        if insertionIndex! < 2  // should only see index == 1
        {
          candidatePost?.insert(before: route.head!, as: .Candidate)
        }
        else if insertionIndex! > n // should only see n+1
        {
          candidatePost?.insert(after: route.tail!, as: .Candidate)
        }
        else
        {
          guard let ref_wp = route.find(post: insertionIndex! - 1) else
            { fatalError("Should never see this... route is hosed up") }
          
          candidatePost?.insert(after: ref_wp, as: .Candidate)
        }
      }
      
      dvc.updateCandidate(candidatePost!)
    }
    
    dvc.applyState()
  }
  
  func start()
  {
    locationManager.delegate = self
    locationManager.allowsBackgroundLocationUpdates = false
    locationManager.requestWhenInUseAuthorization()
    let status = CLLocationManager.authorizationStatus()
    lastRecordedPost = nil
    
    updateState(.Authorization(status))
    
    if route.count == 0 { return }
    
    let deleteRoute =
      {
        (_:UIAlertAction) in
        self.route = WorkingRoute()
        self.dataViewController.applyState()
      }
    
    let keepRoute =
      {
        (_:UIAlertAction) in
        self.dataViewController.updateRoute(self.route)
        self.dataViewController.applyState()
        self.dataViewController.viewPostsOnMap(updateTrackingMode: true)
      }
    
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .medium
    let date = formatter.string(from: route.created)
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    let time = formatter.string(from: route.created)
    
    let name = route.name ?? "unsaved route"
    
    let alert = UIAlertController(title:nil,
                                  message:"What do you want to do with '\(name)' started \(date) at \(time)",
                                  preferredStyle: .alert)
    
    alert.addAction( UIAlertAction(title: "Delete it", style: .destructive, handler: deleteRoute) )
    alert.addAction( UIAlertAction(title: "Continue",  style: .cancel,      handler: keepRoute) )
    
    dataViewController.present(alert, animated: true)
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
  
  
  func updateDeclinationIfNeeded()
  {
    if route.declination != nil && route.declination != 0.0 { return }
    
    if CLLocationManager.headingAvailable()
    {
      locationManager.startUpdatingHeading()
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
              let action = DeletionAction(self, post:post, at:location, inserting:self.insertionIndex )
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
    
    updateDeclinationIfNeeded()
  }
  
  func renumber(post:Int)
  {
    let rc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RenumberViewController") as! RenumberViewController
    
    rc.delegate = self
    rc.setNeedsStatusBarAppearanceUpdate()
    dataViewController.definesPresentationContext = true
    
    self.renumberIndex = post
    
    dataViewController.parent!.present(rc, animated: true)
  }
  
  func renumberView(_ vc: RenumberViewController, didSelect row: Int)
  {
    let oldPost = self.renumberIndex!
    let newPost = (row+1 < oldPost ? row+1 : row+2)
    
    let action = RenumberPostAction(self, from:oldPost, to:newPost)
    
    if action.redo() { UndoManager.shared.add(action) }
  }
  
  // MARK: - Undo/Redo actions
  
  @discardableResult
  func undo(insertion:InsertionAction) -> Bool
  {
    let action =
    {
      let wasInserting = self.state == .Inserting
      self.candidatePost = nil
      
      self.route.remove(post: insertion.post)
      self.dataViewController.updateRoute(self.route)
      self.lastRecordedPost = nil
      self.dataViewController.applyState()
      self.insertionIndex = insertion.post
      
      if wasInserting { self.updateState(.Insert(insertion.post)) }
    }
    
    if insertion.firstUndo
    {
      dataViewController.confirmAction(
        type: .Deletion(insertion.post),
        action: action,
        failure: { UndoManager.shared.cancel(undo:insertion) } )
    }
    else
    {
      action()
    }
    
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
    insertionIndex = deletion.insertionIndexForUndo(ifInsertingAt: insertionIndex)
    dataViewController.updateRoute(route)
    return true
  }
  
  @discardableResult
  func redo(deletion:DeletionAction) -> Bool
  {
    route.remove(post:deletion.post)
    insertionIndex = deletion.insertionIndexForRedo(ifInsertingAt: insertionIndex)
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
    let wasInserting = self.state == .Inserting
    
    candidatePost = nil;
    
    let ok = route.renumber(post:oldPost, as:newPost)
    
    if ok && wasInserting { updateState(.Insert(insertionIndex)) }
        
    dataViewController.updateRoute(route)
    
    return ok
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
  
  func title(for vc: RenumberViewController) -> String?
  {
    guard let post = self.renumberIndex else { return nil }
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
    let post = (row+1 < self.renumberIndex! ? row+1 : row+2)
    return "Post \(post)"
  }
  
  // MARK: - Share Route
  
  func shareRoute()
  {
    
    let activityVC = UIActivityViewController(activityItems: [self], applicationActivities: nil)
    
    activityVC.completionWithItemsHandler =
      {
        (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?)
        in
        activityVC.dismiss(animated: true, completion: nil)
      }
    
    dataViewController.present(activityVC, animated: true, completion: nil)
  }
  
  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
  {
    return "Sample Message"
  }
  
  func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any?
  {
    return route.composeMessageToShare(for:activityType)
  }
  
  func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
  {
    return route.subjectForSharedMessage()
  }
  
  // MARK: - Save Route
  
  enum SaveState
  {
    case Saving
    case SavingAs
    case Replacing
  }
  
  var saveState = SaveState.Saving
  
  func saveRoute()
  {
    let existingRoute = Routes.shared[route.routeID]
    
    if existingRoute == nil
    {
      updateRouteInfoAndSave(as:.Saving)
    }
    else
    {
      let prompt = UIAlertController(title:"Existing Route",
                                     message: "What do you want to do with \(route.name!)",
                                     preferredStyle: .alert)
      
      prompt.addAction(UIAlertAction(title: "Replace it", style: .default,
                                     handler: { _ in self.updateRouteInfoAndSave(as:.Replacing) } ) )
      
      prompt.addAction(UIAlertAction(title: "Save as new...", style: .default,
                                     handler: { _ in self.updateRouteInfoAndSave(as:.SavingAs) } ) )
      
      prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel) )
      
      dataViewController.present(prompt, animated: true)
    }
  }
  
  func updateRouteInfoAndSave(as state:SaveState)
  {
    
    let rc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RouteInfoViewController") as! RouteInfoViewController
    
    rc.delegate = self
    rc.setNeedsStatusBarAppearanceUpdate()
    dataViewController.definesPresentationContext = true
    
    saveState = state
    dataViewController.parent!.present(rc, animated: true)
  }
  
  func updateRouteInfo(withName name: String, description: String?, keepOpen: Bool)
  {
    route.save(withName:name, description:description, withNewID:(saveState == .SavingAs))
    route.locked = (keepOpen==false)
    
    if keepOpen == false && state == .Inserting { updateState(.Pause) }
  }
  
  func route(for controller: RouteInfoViewController) -> Route?
  {
    return route
  }
  
  // MARK: - Routes view controller delegate
  
  func routesViewController(selectedNewRoute newRoute: Route?)
  {
    let action =
    {
      self.route = ( newRoute == nil ? WorkingRoute() : WorkingRoute(from:newRoute!) )
      if self.state == .Inserting { self.updateState(.Pause) }
      self.insertionIndex = nil
      self.renumberIndex  = nil
      self.lastRecordedPost = nil
      self.dataViewController.updateRoute(self.route)
    }
    
    dataViewController.confirmAction(type: .NewWorkingRoute(route, newRoute), action: action )
  }
}
