//
//  PostAnnotation.swift
//  truCourse
//
//  Created by Mike Mayer on 4/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import MapKit

class PostAnnotation : NSObject, MKAnnotation
{
  dynamic var coordinate:  CLLocationCoordinate2D
  dynamic var title:       String?
  dynamic var subtitle:    String?
  
  var waypoint: Waypoint
  {
    didSet
    {
      self.coordinate = waypoint.location
      updateTitle()
    }
  }
  
  init(_ wp:Waypoint, north:NorthType, units:BaseUnitType )
  {
    self.waypoint   = wp
    self.coordinate = wp.location
    
    super.init()
    updateTitle()
  }
  
  func updateTitle()
  {
    self.title    = waypoint.annotationTitle
    self.subtitle = waypoint.annotationSubtitle
  }
  
  func applyOptions()
  {
    updateTitle()
  }
}
