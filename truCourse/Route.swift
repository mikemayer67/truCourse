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
  
  func find(post: Int) -> Waypoint?
  {
    return head?.find(index:post)
  }
  
  var tail : Waypoint?
  {
    return head?.prev
  }

  func restart(at post:Int) -> Bool
  {
    var rval = false
    if let wp = head?.find(index: post)
    {
      wp.reindex()
      head = wp
      rval = true
    }
    return rval
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
  
  func insert(post:Int, at location:CLLocationCoordinate2D)
  {
    let new_wp = Waypoint(location)
    
    if self.head == nil
    {
      if post != 1 { fatalError("Can only insert post #1 into empty route") }
      new_wp.commit()
      self.head = new_wp
    }
    else if post == 1
    {
      new_wp.insert(before: self.head!)
      self.head = new_wp
      new_wp.reindex()
    }
    else
    {
      let ref_wp = self.head?.find(index:post-1)
      if ref_wp == nil  { fatalError("route must contain post #\(post-1) to add post #\(post)") }
      new_wp.insert(after: ref_wp!)
    }
  }
  
  func commit(_ candidate:Waypoint, at index:Int)
  {
    candidate.commit()
    if index == 1
    {
      candidate.reindex()
      head = candidate
    }
  }
  
  func remove(post:Int)
  {
    let wp = head?.find(index: post)
    if wp == nil  { fatalError("route must contain post #\(post) to remove it") }
    
    if wp === head
    {
      head = wp!.next
      if wp === head   // only post remaining
      {
        head = nil
      }
    }
    
    wp!.unlink()
    head?.reindex()
  }
  
  //MARK: - Route info
  
  func setDeclination(_ heading : CLHeading)
  {
    let mag = heading.magneticHeading
    let tru = heading.trueHeading
    self.declination = tru-mag
  }
}
