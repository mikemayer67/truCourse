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
    didSet { update() ; prev?.update() }
  }
  
  private(set) var index        : Int?
  private(set) var bearing      : CLLocationDirection?  // rel. true north
  private(set) var distance     : CLLocationDistance?
  private(set) var candBearing  : CLLocationDirection?
  private(set) var candDistance : CLLocationDistance?
  
  private(set) var next   : Waypoint?
  private(set) var prev   : Waypoint?
  private(set) var cand   : Waypoint?
  
  func string() -> String
  {
    let index = self.index ?? 0
    let dist = self.distance ?? 0.0
    let bearing = self.bearing?.dms ?? "n/a"
    return String(format: "%2d: (%@, %@) [ %f @ %@",
                  index, location.latitude.dms, location.longitude.dms,
                  dist, bearing)
  }
  
  // MARK: - Constructors & Encoders
  
  init(_ location: CLLocationCoordinate2D)
  {
    self.location = location
  }
  
  init(with data:NSDictionary, after:Waypoint?)
  {
    location = data.value(forKey: "location") as! CLLocationCoordinate2D
    
    if after == nil
    {
      next = self
      prev = self
    }
    else
    {
      next = after!.next
      prev = after
      prev!.next = self
      next!.prev = self
    }
    
    update()
    prev!.update()
  }
  
  func save(into route: NSMutableArray)
  {
    let data = NSMutableDictionary()
    data.setValue(location, forKey: "location")
    
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
    guard nextPoint.prev != nil else
    { fatalError("Attempted to insert before an unlinked Waypoint") }
    
    _insert(as:type){ self.prev = nextPoint.prev; self.next = nextPoint }
  }
  
  func insert(after priorPoint:Waypoint, as type:InsertionType = .Committed)
  {
    guard priorPoint.next != nil else
    { fatalError("Attempted to insert after an unlinked Waypoint") }
    
    _insert(as:type){ self.next = priorPoint.next; self.prev = priorPoint }
  }

  private func _insert(as type:InsertionType, link:()->() )
  {
    guard next == nil else
    {
      let qualifier = (type == .Candidate ? "as candidate" : "to route")
      fatalError("Attempted to add linked Waypoint \(qualifier)")
    }
    
    link()
    
    switch(type)
    {
    case .Candidate:
      prev!.cand = self
      
    case .Committed:
      prev!.cand = nil
      prev!.next = self
      next!.prev = self
    }
    
    update()
    prev!.update()
    
  }
  
  func commit()
  {
    if next == nil, prev == nil  // first waypoint in a new route
    {
      next = self
      prev = self
      index = 1
    }
    else // add candidate (in-place) to the route
    {
      guard prev!.cand === self else
      { fatalError("Attempted to commit non-candidate Waypoint") }
      
      next!.prev = self
      prev!.next = self
      prev!.cand = nil
      
      update()
      prev!.update()
    }
  }
  
  func unlink()
  {
    if prev == nil { return }
    
    if prev!.cand === self
    {
      prev!.cand = nil
    }
    else
    {
      if prev!.cand != nil
      {
        guard prev!.cand!.next === self else
        { fatalError("Improperly linked candidate encountered") }
        
        prev!.cand!.next = next
        prev!.cand!.update()
      }
      
      prev!.next = next
      next!.prev = prev
    }
    
    prev!.update()

    prev = nil
    next = nil
  }
  
  // MARK: - Route iterator and iterated properties
  
  var length : Int
  {
    var count = 0
    iterate( { _ in count += 1 } )
    return count
  }
  
  func find(index:Int) -> Waypoint?
  {
    var rval : Waypoint?
    iterate( { wp in if wp.index == index { rval = wp } } )
    return rval
  }
  
  func reindex()
  {
    var nextIndex = 1
    iterate( { wp in wp.index = nextIndex; nextIndex += 1 } )
  }
  
  func iterate(_ task:(Waypoint)->Void )
  {
    task(self)

    if next == nil || next === self { return }
    
    var cur = next!
    while( cur !== self )
    {
      task(cur)
      cur = cur.next!
    }
  }
  
  // MARK: - Waypoint properties
  
  func update()
  {
    (    bearing,    distance) = calcBearing(to: self.next)
    (candBearing,candDistance) = calcBearing(to: self.cand)
  }
  
  func calcBearing(to dst:Waypoint?) -> (CLLocationDirection?,CLLocationDistance?)
  {
    if dst == nil || dst === self { return(nil,nil) }
    
    // The following assumes constant local radii of curvature of the earth along the
    // entire length of the path connecting two waypoints.  It also assumes that the
    // earth is locally flat enough to apply Pythagorean theorem. Unless this app is
    // used to create HUGE orienteering coarses, this will be plenty sufficient.
    // https://en.wikipedia.org/wiki/Earth_radius
    
    let a = Constants.earthEquatorialRadius
    let b = Constants.earthPolarRadius
    
    let lat = location.latitude  * Constants.deg  // radians
    let lon = location.longitude * Constants.deg  // radians
    
    let nextLat = dst!.location.latitude  * Constants.deg  // radians
    let nextLon = dst!.location.longitude * Constants.deg  // radians
    
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
    
    return( atan2( dx, dy ) / Constants.deg, sqrt( dx*dx + dy*dy ) )
  }
  
  var annotationTitle : String?
  {
    var rval : String?
    if candBearing != nil && candDistance != nil
    {
      rval = _genTitle(candBearing,candDistance)
    }
    else if bearing != nil && distance != nil
    {
      rval = _genTitle(bearing,distance)
    }
    return rval
  }
  
  var annotationSubtitle : String?
  {
    if candBearing  == nil { return nil }
    if candDistance == nil { return nil }
    if bearing      == nil { return nil }
    if distance     == nil { return nil }

    return _genTitle(bearing,distance)
  }
  
  private func _genTitle(_ bearing : CLLocationDirection?, _ distance : CLLocationDistance?) -> String?
  {
    if bearing == nil || distance == nil { return nil }
    
    let options = Options.shared
    
    var decl = 0.0
    if options.northType == .Magnetic
    {
      decl = options.declination ?? 0.0
    }
    
    let deg = Int( bearing! - decl + 360.5 ) % 360  // 360.5 = 360 for mod + 0.5 for rounding to nearest integer
    
    var dist = ""
    switch options.baseUnit
    {
    case .English:
      let ft = Int(distance!/0.3048 + 0.5)
      if ft >= 10560
      {
        dist = String(format:"%d miles %d ft", ft/5280, ft%5280)
      }
      else if ft >= 5280
      {
        dist = String(format:"1 mile %d ft",ft%5280)
      }
      else
      {
        dist = String(format:"%d ft",ft)
      }
      
    case .Metric:
      if distance! > 1000.0
      {
        dist = String(format:"%.2f km", 0.001 * distance!)
      }
      else
      {
        dist = String(format:"%d m", Int(distance! + 0.5) )
      }
    }
    
    return "\(dist) @ \(deg)°"
  }
}
