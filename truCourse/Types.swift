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

enum VisualizationType : Int
{
  case MapView = 0
  case BearingView = 1
  case LatLonView = 2
  
  func next() -> VisualizationType
  {
    switch self
    {
    case .MapView:     return .BearingView
    case .BearingView: return .LatLonView
    case .LatLonView:  return .MapView
    }
  }
  
  func prev() -> VisualizationType
  {
    switch self
    {
    case .MapView:     return .LatLonView
    case .BearingView: return .MapView
    case .LatLonView:  return .BearingView
    }
  }
}

protocol VisualizationView : class
{
  var visualizationType : VisualizationType { get }
  
  func applyOptions(_ options:Options)
}

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
  case Idle           // Authorized
  case Inserting(Int) // insertion index (0 = new start point)
  case Editing(Int)   // editting index
}

enum AppStateTransition
{
  case Authorization(CLAuthorizationStatus)
  
  case Start
  case Enabled(Bool)        // user starting/pausing use of location services
  case Insert(Int)          // index indicates which post to insert AFTER (0 = before first post)
  case Edit(Int)            // index indicates which post to begin editing
  case Save(Bool)           // flag indicating whether to lock the route for futuere edits
}

