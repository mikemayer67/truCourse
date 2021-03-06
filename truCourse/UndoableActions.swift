//
//  UndoableActions.swift
//  truCourse
//
//  Created by Mike Mayer on 4/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import CoreLocation

class RouteEditAction : UndoableAction
{
  func undo()->Bool { fatalError("undo must be subclassed") }
  func redo()->Bool { fatalError("redo must be subclassed") }
}


class InsertionAction : RouteEditAction
{
  let post           : Int
  let location       : CLLocationCoordinate2D
  
  private(set) var firstUndo = true

  init(post:Int, at location:CLLocationCoordinate2D)
  {
    self.post     = post
    self.location = location
  }
  
  override func undo()->Bool
  {
    let rval = DataController.shared.undo(insertion:self)
    self.firstUndo = false
    return rval
  }
  override func redo()->Bool { return DataController.shared.redo(insertion:self) }
}

class DeletionAction : RouteEditAction
{
  let post      : Int
  let location  : CLLocationCoordinate2D
  let oldIndex  : Int?
  let newIndex  : Int?

  init(post:Int, at location:CLLocationCoordinate2D, inserting:Int?)
  {
    self.post      = post
    self.location  = location
    
    if let curIndex = inserting
    {
      self.oldIndex = curIndex
      self.newIndex = ( post < curIndex ? curIndex - 1 : curIndex )
    }
    else
    {
      self.oldIndex = nil
      self.newIndex = nil
    }
  }
  
  override func undo()->Bool { return DataController.shared.undo(deletion:self) }
  override func redo()->Bool { return DataController.shared.redo(deletion:self) }
  
  func insertionIndexForRedo(ifInsertingAt curIndex:Int?) -> Int?
  {
    if curIndex == nil        { return nil }
    if oldIndex == nil        { return nil }
    if curIndex! == oldIndex! { return newIndex }
    
    return ( post < curIndex! ? curIndex!-1 : curIndex! )
  }
  
  func insertionIndexForUndo(ifInsertingAt curIndex:Int?) -> Int?
  {
    if curIndex == nil        { return nil }
    if oldIndex == nil        { return nil }
    if curIndex! == newIndex! { return oldIndex }
    
    return ( post < curIndex! ? curIndex!+1 : curIndex! )
  }
}

class NewStartAction : RouteEditAction
{
  let post : Int
  
  init(post:Int)
  {
    self.post = post
  }
  
  override func undo()->Bool { return DataController.shared.undo(newStart:self) }
  override func redo()->Bool { return DataController.shared.redo(newStart:self) }
}

class ReverseRouteAction : RouteEditAction
{
  var insertionIndex : Int?
  
  init(insertionIndex index:Int?) { self.insertionIndex = index }
  override func undo()->Bool { return DataController.shared.undo(reverseRoute:self) }
  override func redo()->Bool { return DataController.shared.redo(reverseRoute:self) }
}

class RenumberPostAction : RouteEditAction
{
  let oldPost : Int
  let newPost : Int
  init(from oldPost:Int, to newPost:Int)
  {
    self.oldPost = oldPost
    self.newPost = newPost
  }
  
  override func undo()->Bool { return DataController.shared.undo(renumberPost:self) }
  override func redo()->Bool { return DataController.shared.redo(renumberPost:self) }
}

class MovePostAction : RouteEditAction
{
  let post        : Int
  let oldLocation : CLLocationCoordinate2D
  let newLocation : CLLocationCoordinate2D
  
  init(post:Int, from oldLocation:CLLocationCoordinate2D, to newLocation:CLLocationCoordinate2D)
  {
    self.post        = post
    self.oldLocation = oldLocation
    self.newLocation = newLocation  }
  
  override func undo()->Bool { return DataController.shared.undo(movePost:self) }
  override func redo()->Bool { return DataController.shared.redo(movePost:self) }
}
