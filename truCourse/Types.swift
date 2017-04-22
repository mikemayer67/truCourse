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
