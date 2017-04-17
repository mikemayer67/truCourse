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
  var post:               Int
  dynamic var coordinate: CLLocationCoordinate2D
  dynamic var title:      String?
  
  var bearing:  CLLocationDirection?  { didSet { updateTitle() } }
  var distance: CLLocationDistance?   { didSet { updateTitle() } }
  
  var north:    NorthType
  var units:    BaseUnitType
  var decl:     CLLocationDegrees?   { didSet { if north == .Magnetic { updateTitle() } } }
  
  init(_ wp:Waypoint, north:NorthType, units:BaseUnitType )
  {
    self.post       = wp.index!
    self.coordinate = wp.location
    self.bearing    = wp.bearing
    self.distance   = wp.distance
    
    self.north      = north
    self.units      = units
    
    super.init()
    
    updateTitle()
  }
  
  func updateTitle()
  {
    if bearing == nil || distance == nil
    {
      self.title = nil
    }
    else
    {
      var delta = 0.0
      if decl != nil && north == .Magnetic
      {
        delta = decl!
      }
      
      let deg = (360 + Int( bearing! + delta + 0.5 )) % 360
      
  
      var dist = ""
      switch units
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
      
      self.title = "\(dist) @ \(deg)°"
    }
  }
  
  func update(_ wp:Waypoint)
  {
    self.coordinate = wp.location
    self.bearing    = wp.bearing
    self.distance   = wp.distance
    
    updateTitle()
  }
  
  func applyOptions(_ options:Options)
  {
    self.north     = options.northType
    self.units     = options.baseUnit
    
    updateTitle()
  }
}
