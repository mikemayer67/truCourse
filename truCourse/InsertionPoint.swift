//
//  InsertionPoint.swift
//  truCourse
//
//  Created by Mike Mayer on 3/30/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import CoreLocation

class InsertionPoint
{
  private(set) var candidate: Waypoint
  
  private(set) var after: Waypoint?
  private(set) var before: Waypoint?
  
  init(_ loc:CLLocationCoordinate2D)
  {
    candidate = Waypoint(loc)
  }
  
  init(_ loc:CLLocationCoordinate2D, after waypoint: Waypoint)
  {
    guard waypoint.index != nil else
    { fatalError("Attempted to create insertion point to unlinked waypoint") }
    
    self.candidate = Waypoint(loc)
    self.candidate.insert(after: waypoint, as: .Candidate)
    self.after = waypoint
  }
  
  init(_ loc:CLLocationCoordinate2D, before waypoint: Waypoint)
  {
    guard waypoint.index != nil else
    { fatalError("Attempted to create insertion point to unlinked waypoint") }
    
    self.candidate = Waypoint(loc)
    self.candidate.insert(before: waypoint, as: .Candidate)
    self.before = waypoint
  }
  
  var string : String
  {
    var rval = "Candidate:\(candidate.index) "
    if after != nil { rval = rval + "After:\(after!.index)" }
    if before != nil { rval = rval + "Before:\(before!.index)" }
    return rval
  }
}
