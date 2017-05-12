//
//  PostAnnotation.swift
//  truCourse
//
//  Created by Mike Mayer on 4/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import MapKit
import CoreGraphics

class PostAnnotation : NSObject, MKAnnotation
{
  dynamic var coordinate:  CLLocationCoordinate2D
  dynamic var title:       String?
  dynamic var subtitle:    String?
  
  private(set) var image        : UIImage
  private(set) var centerOffset : CGPoint
  
  var waypoint: Waypoint
  {
    didSet
    {
      self.coordinate = waypoint.location
      
      let pi = PostImage.library[waypoint.index!]
      self.image = pi.image
      
      updateTitle()
    }
  }
  
  init(_ wp:Waypoint, north:NorthType, units:BaseUnitType )
  {
    self.waypoint     = wp
    self.coordinate   = wp.location
    
    let pi = PostImage.library[wp.index!]
    
    self.image        = pi.image
    self.centerOffset = pi.centerOffset
      
    super.init()
    updateTitle()
  }
  
  func updateTitle()
  {
    self.title    = waypoint.annotationTitle
    self.subtitle = waypoint.annotationSubtitle
  }
}
