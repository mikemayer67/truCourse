//
//  WorkingRegion.swift
//  truCourse
//
//  Created by Mike Mayer on 5/2/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import MapKit

class WorkingRegion
{
  private(set) var posts : MKCoordinateRegion
  
  private var minLat : CLLocationDegrees =   90.0
  private var maxLat : CLLocationDegrees =  -90.0
  private var minLon : CLLocationDegrees =  180.0  // cannot span dateline
  private var maxLon : CLLocationDegrees = -180.0
  
  init()
  {
    posts = MKCoordinateRegion()
  }
  
  convenience init( posts:[Waypoint], user:CLLocationCoordinate2D? = nil )
  {
    self.init()
    self.update( posts: posts )
  }
  
  func update(posts waypoints:[Waypoint] )
  {
    maxLat = -90.0
    minLat =  90.0
    maxLon = -180.0   // will break crossing dateline
    minLon =  180.0
    
    waypoints.forEach { (wp:Waypoint) in
      let lat = wp.location.latitude
      let lon = wp.location.longitude
      if lat < minLat { minLat = lat }
      if lon < minLon { minLon = lon }
      if lat > maxLat { maxLat = lat }
      if lon > maxLon { maxLon = lon }
    }
    
    posts.center = CLLocationCoordinate2D(latitude:  0.5 * ( maxLat + minLat ),
                                          longitude: 0.5 * ( maxLon + minLon ) )
    
    posts.span = MKCoordinateSpan(latitudeDelta: 1.2*(maxLat - minLat),
                                  longitudeDelta: 1.2*(maxLon - minLon) )
  }
}
