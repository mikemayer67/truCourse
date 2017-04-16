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
  private(set) var declination    : CLLocationDegrees?
  
  private(set) var head           : Waypoint?
  
  private(set) var insertionHistory = [Waypoint]()
 
  
  var dirty  : Bool = false
  var locked : Bool = false
  
  // MARK: - Route Indexing
  
  var isEmpty : Bool
  {
    return head == nil
  }
  
  var count : Int
  {
    return head?.length ?? 0
  }
  
  subscript(index: Int) -> Waypoint?
  {
    return head?.find(index:index)
  }
  
  var tail : Waypoint?
  {
    return head?.prev
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
    
    if let waypoints = routeData.value(forKey: "waypoints") as? [NSDictionary]
    {
      var tail : Waypoint?
      for wp in waypoints
      {
        tail = Waypoint(with: wp, after: tail)
        if head == nil { head = tail }
      }
    }
    
    dirty  = false
    locked = lastSaved != nil
    
    head?.reindex()
  }
    
  func save(into routes:NSMutableArray)
  {
    let data = NSMutableDictionary()
    
    if (locked && ( dirty || lastSaved == nil ) )
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
    head?.iterate() { (wp:Waypoint) in wp.save(into:waypoints) }
    if waypoints.count > 0 { data.setValue(waypoints, forKey: "waypoints") }
    
    routes.add(data)
    
    dirty  = false
  }
  
  func insert(_ ip : InsertionPoint)
  {
    let cand = ip.candidate
    cand.commit()
    
    if head == nil || (ip.before != nil && ip.before! === head)
    {
      head = cand
    }
    
    insertionHistory.append(cand)
    
    head!.reindex()
  }
  
  func undoInsertion(update insertionPoint:InsertionPoint?)
  {
    if insertionHistory.isEmpty { return }
        
    let wp = insertionHistory.removeLast()
    
    insertionPoint?.relink(dropping:wp)
    
    if head === wp
    {
      head = wp.next
      if head === wp
      {
        head = nil
      } // head is only waypoint left in route
    }
    
    wp.unlink()
    
    head?.reindex()
  }
  
  //MARK: - Route info
  
  func setDeclination(_ heading : CLHeading)
  {
    let mag = heading.magneticHeading
    let tru = heading.trueHeading
    self.declination = mag - tru
  }
}
