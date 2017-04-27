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
  let dataController : DataController

  init(_ dc:DataController)
  {
    self.dataController = dc
  }
  
  func undo() { fatalError("undo must be subclassed") }
  func redo() { fatalError("redo must be subclassed") }
}


class InsertionAction : RouteEditAction
{
  let post           : Int
  let location       : CLLocationCoordinate2D
  
  init(_ dc:DataController, post:Int, at location:CLLocationCoordinate2D)
  {
    self.post     = post
    self.location = location
    super.init(dc)
  }
  
  override func undo() { dataController.undo(insertion:self) }
  override func redo() { dataController.redo(insertion:self) }
}

class DeletionAction : RouteEditAction
{
  let post           : Int
  let location       : CLLocationCoordinate2D
  
  init(_ dc:DataController, post:Int, at location:CLLocationCoordinate2D)
  {
    self.post           = post
    self.location       = location
    super.init(dc)
  }
  
  override func undo() { dataController.undo(deletion:self) }
  override func redo() { dataController.redo(deletion:self) }
}

class NewStartAction : RouteEditAction
{
  let post : Int
  
  init(_ dc:DataController, post:Int)
  {
    self.post = post
    super.init(dc)
  }
  
  override func undo() { dataController.undo(newStart:self) }
  override func redo() { dataController.redo(newStart:self) }
}

class ReverseRouteAction : RouteEditAction
{
  override func undo() { dataController.undo(reverseRoute:self) }
  override func redo() { dataController.redo(reverseRoute:self) }
}

class RenumberPostAction : RouteEditAction
{
  let oldPost : Int
  let newPost : Int
  init(_ dc:DataController, from oldPost:Int, to newPost:Int)
  {
    self.oldPost = oldPost
    self.newPost = newPost
    super.init(dc)
  }
  
  override func undo() { dataController.undo(renumberPost:self) }
  override func redo() { dataController.redo(renumberPost:self) }
}
