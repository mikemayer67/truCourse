//
//  Types.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

enum NorthType : Int
{
  case True     = 0
  case Magnetic = 1
}

enum BaseUnitType : Int
{
  case Metric  = 0
  case English = 1
}

enum AppState
{
  case Uninitialized
  case Disabled       // Location Service not authorized
  case Paused         // User disabled location updates
  case Idle           // Authorized and user enabled
  case Inserting      // Inserting new candidate
}

enum AppStateTransition
{
  case Authorization(CLAuthorizationStatus)
  
  case Start
  case Enabled(Bool)  // user starting/pausing use of location services
  case Insert(Int?)   // location to begin insertion (nil inserts at end)
  case Pause          // stop inserting or editing candidate waypoint
  
  var string : String
  {
    var rval : String!
    switch self
    {
    case .Authorization(let status):
      switch status
      {
      case .authorizedAlways: rval = "Authorization (Always)"
      case .authorizedWhenInUse: rval = "Authorization (When in Use)"
      case .denied: rval = "Authorization (Denied)"
      case .notDetermined: rval = "Authorization (Not determined)"
      case .restricted: rval = "Authorization (restricted)"
      }
    case .Start:               rval = "Start"
    case .Enabled(let state):  rval = "Enabled(\(state))"
    case .Insert(let index):   rval = "Insert(\(index))"
    case .Pause:               rval = "Pause"
    }
    return rval
  }
}

enum ActionType
{
  case Insertion
  case Deletion(Int)
  case NewStart(Int)
  case ReverseRoute
  case RenumberPost(Int)
  case MovePost(Int)
}
