//
//  Route.swift
//  truCourse
//
//  Created by Mike Mayer on 3/16/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import CoreLocation

class Route
{
  var name                  : String?
  var description           : String?
  
  private(set) var created  : Date
  private(set) var modified  : Date?
  
  private(set) var startPoint     : Waypoint?
  private(set) var candidatePoint : Waypoint?
  private(set) var declination    : CLLocationDegrees?
  
  init()
  {
    created = Date()
  }
  
  
}
