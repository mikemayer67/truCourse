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

enum MapOrientation : Int
{
  case North     = 0
  case Heading   = 1
}

enum NorthType : Int
{
  case True     = 0
  case Magnetic = 1
}

enum HeadingAccuracy : CLLocationDegrees
{
  case Precise = 1.0
  case Good    = 2.0
  case Medium  = 5.0
  case Coarse  = 10.0
  
  func index() -> Int
  {
    switch self
    {
    case .Precise: return 0
    case .Good:    return 1
    case .Medium:  return 2
    case .Coarse:  return 3
    }
  }
  
  mutating func set(byIndex: Int) -> Void
  {
    switch byIndex
    {
    case 0: self = .Precise
    case 1: self = .Good
    case 2: self = .Medium
    case 3: self = .Coarse
    default: self = .Good
    }
  }
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
  case Editing(Int)   // editting index
}

enum AppStateTransition
{
  case Authorization(CLAuthorizationStatus)
  
  case Start
  case Enabled(Bool)  // user starting/pausing use of location services
  case Insert(Int?)   // location to begin insertion (nil inserts at end)
  case Edit(Int)      // index indicates which post to begin editing
  case Cancel         // stop inserting or editing candidate waypoint
  case Save(Bool)     // flag indicating whether to lock the route for futuere edits
}

extension CLLocationDegrees
{
  init(_ deg:Int, _ min:Int = 0, _ sec:Int = 0)
  {
    let ms = Double(min) + Double(sec)/60.0
    if deg < 0 { self = Double(deg) - ms }
    else       { self = Double(deg) + ms }
  }
  
  var dms : String
  {
    let neg = self < 0.0
    var sec   = Int(3600.0 * (neg ? -self : self) + 0.5)
    var min = Int(sec/60)
    sec %= 60
    var deg = Int(min/60)
    min %= 60
    if neg { deg = -deg }
    let rval = String(format: "%4dº%02d'%02d\"", deg, min, sec)
    return rval
  }
}


