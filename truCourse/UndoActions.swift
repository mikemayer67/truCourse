//
//  UndoActions.swift
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
  let route          : Route

  init(_ dc:DataController, on route:Route)
  {
    self.dataController = dc
    self.route = route
  }
  
  func undo() { fatalError("undo must be subclassed") }
  func redo() { fatalError("redo must be subclassed") }
}


class InsertionAction : RouteEditAction
{
  let post           : Int
  let location       : CLLocationCoordinate2D
  
  init(_ dc:DataController, post:Int, at location:CLLocationCoordinate2D, on route:Route)
  {
    self.post     = post
    self.location = location
    super.init(dc, on:route)
  }
  
  override func undo() { dataController.undo(insertion:self) }
  override func redo() { dataController.redo(insertion:self) }
}

class DeletionAction : RouteEditAction
{
  let post           : Int
  let location       : CLLocationCoordinate2D
  
  init(_ dc:DataController, post:Int, at location:CLLocationCoordinate2D, on route:Route)
  {
    self.post           = post
    self.location       = location
    super.init(dc, on:route)
  }
  
  override func undo() { dataController.undo(deletion:self) }
  override func redo() { dataController.redo(deletion:self) }
}

class NewStartAction : RouteEditAction
{
  let post : Int
  
  init(_ dc:DataController, post:Int, on route:Route)
  {
    self.post = post
    super.init(dc,on:route)
  }
  
  override func undo() { dataController.undo(newStart:self) }
  override func redo() { dataController.redo(newStart:self) }
}
