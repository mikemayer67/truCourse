//
//  Waypoint.swift
//  truCourse
//
//  Created by Mike Mayer on 3/15/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

// Waypoints are the building blocks of a Route.
//
// As such, they are inherently ordered in a ring.  Therefore, Routes are implemented
//  as a double-linked ring of Waypoints (a double-link list where last node points 
//  to first node)
// 
// Each Waypoint is assigned an index once it is inserted into the ring.
//   Candidate waypoints (Waypoints not in the ring) have a nil index
//   The first waypoint is identified by an index of 1
//   Subsequent waypoints have indexes 1 greater than their predecessor
//
// Each Waypoint MAY have a candidate successor waypoint assigned it.
//   Candidate waypoints are disallowed from being part of a ring or
//   having sub-candidates.
// 
// Each Waypoint stores the distance and bearing (relative to true north)
//   to the subsequent point.  If the waypoint has a candidate successor,
//   the distance and bearing are based on the candidate.  If the successor
//   is the waypoint itself (i.e. a ring of only 1 waypoint), the distance
//   and bearing are nil.
// The offset from true north to magnetic north is a property of the route.
//   The magnetic bearing between waypoints must be computed using the 
//   true bearing associated with the waypoint and the declination associated
//   with the route.
// The distance and bearing must be updated each time a new waypoint or
//   candidate waypoint is added or removed from the route.


import Foundation
import CoreLocation

class Waypoint
{
  var location               : CLLocationCoordinate2D
  {
    didSet { update() ; _prev?.update() }
  }
  
  private(set) var index    : Int?
  private(set) var bearing  : CLLocationDirection?  // rel. true north
  private(set) var distance : CLLocationDistance?
  
  private      var _next   : Waypoint?
  private      var _prev   : Waypoint?
  private      var _cand   : Waypoint?
  
  // MARK: - Constructors & Encoders
  
  init(_ location: CLLocationCoordinate2D)
  {
    self.location = location
  }
  
  init(with data:NSDictionary, after:Waypoint?)
  {
    location = data.value(forKey: "location") as! CLLocationCoordinate2D
    bearing  = data.value(forKey: "bearing")  as? CLLocationDirection
    distance = data.value(forKey: "distance") as? CLLocationDistance
    
    if after == nil
    {
      _next = self
      _prev = self
    }
    else
    {
      _next = after!._next
      _prev = after
      _prev!._next = self
      _next!._prev = self
    }
  }
  
  func save(into route: NSMutableArray)
  {
    let data = NSMutableDictionary()
    data.setValue(location, forKey: "location")
    
    if bearing  != nil { data.setValue(bearing,  forKey: "bearing")  }
    if distance != nil { data.setValue(distance, forKey: "distance") }
    
    route.add(data)
  }
  
  // MARK: - Route linkage
  
  enum InsertionType
  {
    case Committed
    case Candidate
  }
  
  func insert(before nextPoint:Waypoint, as type:InsertionType = .Committed)
  {
    guard nextPoint._prev != nil else
    { fatalError("Attempted to insert before an unlinked Waypoint") }
    
    _insert(as:type){ self._prev = nextPoint._prev; self._next = nextPoint }
  }
  
  func insert(after priorPoint:Waypoint, as type:InsertionType = .Committed)
  {
    guard priorPoint._next != nil else
    { fatalError("Attempted to insert after an unlinked Waypoint") }
    
    _insert(as:type){ self._next = priorPoint._next; self._prev = priorPoint }
  }

  private func _insert(as type:InsertionType, link:()->() )
  {
    guard _next == nil else
    {
      let qualifier = (type == .Candidate ? "as candidate" : "to route")
      fatalError("Attempted to add linked Waypoint \(qualifier)")
    }
    
    link()
    
    switch(type)
    {
    case .Candidate:
      _prev!._cand = self
      
    case .Committed:
      _prev!._cand = nil
      _prev!._next = self
      _next!._prev = self
    }
    
    update()
    _prev!.update()
    
  }
  
  func commit()
  {
    if _next == nil, _prev == nil  // first waypoint in a new route
    {
      _next = self
      _prev = self
      index = 1
    }
    else // add candidate (in-place) to the route
    {
      guard _prev!._cand === self else
      { fatalError("Attempted to commit non-candidate Waypoint") }
      
      _next!._prev = self
      _prev!._next = self
      _prev!._cand = nil
    }
  }
  
  // MARK: - Route iterator and iterated properties
  
  var length : Int
  {
    var count = 0
    iterate( { _ in count += 1 } )
    return count
  }
  
  func reindex()
  {
    var nextIndex = 1
    iterate( { wp in wp.index = nextIndex; nextIndex += 1 } )
  }
  
  func iterate(_ task:(Waypoint)->Void )
  {
    task(self)

    if _next == nil || _next === self { return }
    
    var cur = _next!
    while( cur !== self )
    {
      task(cur)
      cur = cur._next!
    }
  }
  
  // MARK: - Waypoint properties
  
  func update()
  {
    if _next == nil || _next === self
    {
      distance = nil
      bearing  = nil
      return
    }
    
    // The following assumes constant local radii of curvature of the earth along the
    // entire length of the path connecting two waypoints.  It also assumes that the
    // earth is locally flat enough to apply Pythagorean theorem. Unless this app is
    // used to create HUGE orienteering coarses, this will be plenty sufficient.
    // https://en.wikipedia.org/wiki/Earth_radius
    
    let a = Constants.earthEquatorialRadius
    let b = Constants.earthPolarRadius
    
    let lat = location.latitude  * Constants.deg  // radians
    let lon = location.longitude * Constants.deg  // radians
    
    let dst = ( _cand == nil ? _next : _cand )!
    
    let nextLat = dst.location.latitude  * Constants.deg  // radians
    let nextLon = dst.location.longitude * Constants.deg  // radians
    
    let cosLat = cos(lat)
    let sinLat = sin(lat)
    
    let t = sqrt(a*a*cosLat*cosLat + b*b*sinLat*sinLat)
    
    let Rns = a*a*b*b / ( t*t*t )
    let Rew = a*a / t
    
    let dLat = nextLat - lat
    var dLon = nextLon - lon
    
    while dLon >  Double.pi { dLon -= 2.0 * Double.pi }
    while dLon < -Double.pi { dLon += 2.0 * Double.pi }
    
    let dx = Rew * dLon
    let dy = Rns * dLat
    
    distance = sqrt( dx*dx + dy*dy )
    bearing  = atan2( dx, dy ) / Constants.deg
  }
}
