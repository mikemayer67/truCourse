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
  var name                        : String?
  var description                 : String?
 
  private(set) var routeID        : Int
  private(set) var created        : Date
  private(set) var lastSaved      : Date?
  
  private(set) var startPoint     : Waypoint?
  private(set) var candidatePoint : Waypoint?
  private(set) var declination    : CLLocationDegrees?
  
  var dirty  : Bool = false
  var locked : Bool = false
  
  // MARK: - Route Indexing
  
  var isEmpty : Bool
  {
    guard startPoint != nil else { return true }
    return startPoint!.length == 0
  }
  
  var count : Int
  {
    return startPoint?.length ?? 0
  }
  
  subscript(index: Int) -> Waypoint?
  {
    print("Route: Need to implmeent subscript")
    return nil
  }

  // MARK: - Constructors and Encoding

  init()
  {
    routeID = Route.nextRouteID
    created = Date()
    
    Route.nextRouteID += 1
  }
  
  init( with routeData : NSDictionary )
  {
    routeID     = routeData.value(forKey: "routeID")     as! Int
    
    Route.nextRouteID = routeID + 1 // see magic of nextRouteID extension, it never decreases
    
    created     = routeData.value(forKey: "created")     as! Date
    lastSaved   = routeData.value(forKey: "lastSaved")   as? Date
    
    name        = routeData.value(forKey: "name")        as? String
    description = routeData.value(forKey: "description") as? String
    
    declination = routeData.value(forKey: "declination") as? CLLocationDegrees
    
    var waypoints : [NSDictionary]?
    waypoints = routeData.value(forKey: "waypoints") as? [NSDictionary]
    
    if waypoints != nil
    {
      var tail : Waypoint?
      for waypointData in waypoints!
      {
        tail = Waypoint(with: waypointData, after: tail)
        if startPoint == nil { startPoint = tail }
      }
    }
    
    startPoint?.reindex()
  }
    
  func save(into routes:NSMutableArray)
  {
    let data = NSMutableDictionary()
    
    if locked && ( dirty || lastSaved == nil )
    {
      lastSaved = Date()
    }
    
    data.setValue(routeID, forKey: "routeID")
    data.setValue(created, forKey: "created")
    
    if lastSaved   != nil { data.setValue(lastSaved,   forKey: "lastSaved")    }
    if name        != nil { data.setValue(name,        forKey: "name")        }
    if description != nil { data.setValue(description, forKey: "description") }
    if declination != nil { data.setValue(declination, forKey: "declination") }
    
    let waypoints = NSMutableArray()
    startPoint?.iterate() { (wp:Waypoint) in wp.save(into:waypoints) }
    if waypoints.count > 0 { data.setValue(waypoints, forKey: "waypoints") }
    
    routes.add(data)
    
    dirty = false
  }
}
