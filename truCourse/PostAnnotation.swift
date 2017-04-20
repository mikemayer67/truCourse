//
//  PostAnnotation.swift
//  truCourse
//
//  Created by Mike Mayer on 4/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import MapKit
import CoreGraphics

// MARK: - Post Image

/*********************************************
 
 |<-marker width-->|
 
 ---   +-----------------+   ---                 Because of issues with drawing text, I am
 ^    |                 |    ^                  going to skip using affine transforms to make
 |    |                 |    |                  the coordintes more "natural".  Rather, I am
 |    |                 |    marker height      using my own method to convert the coordinates
 |    |                 |    |                  I would like to use (origin at the point, +y=up]
 |    |                 |    v                  to CoreGraphics coordinates (origin in upper-left, +y=down].
 |    +-----+     +-----+   ---
 |          |     |                             Note that I will also apply a skew to this during
 |          |     |                             the conversion.
 post       |     |
 height     |     |                             x_cg = x + image_width/2
 |          |     |                             y_cg = image_height - (y + x*skew)
 |          |     |  ___
 |          \     /   ^                              +-                               -+
 |           \   /    | point height                 |       1             skew      0 |
 |            \ /     v                          T = |       0             -1        0 |
 v             V     ---                             | image_width/2   image_height  1 |
 ---                                                  +-                               -+
 |<--->|
 post width
 
 ***********************************************/

let postWidth    : CGFloat =  4.0
let postHeight   : CGFloat = 34.0
let pointHeight  : CGFloat =  6.0
let markerWidth  : CGFloat = 18.0
let markerHeight : CGFloat = 15.0

let postSkew     : CGFloat =  0.2

let imageWidth  = CGFloat(markerWidth)
let imageHeight = CGFloat(postHeight) + 0.5 * postSkew * CGFloat(postWidth)

fileprivate func T(_ x:CGFloat, _ y:CGFloat) -> CGPoint
{
  let cgx = x + 0.5*imageWidth
  let cgy = imageHeight - ( y + postSkew * x )
  
  return CGPoint(x:cgx, y:cgy)
}

fileprivate class PostImages
{
  static var images = [Int:UIImage]()
  
  static func get(_ index : Int) -> UIImage
  {
    var im = PostImages.images[index]
    if im == nil
    {
      UIGraphicsBeginImageContext(CGSize(width:imageWidth, height:imageHeight))
      let context = UIGraphicsGetCurrentContext();
      
      let path = CGMutablePath()
      path.addLines(between: [ T(  0.0,               0.0 ),
                               T( -0.5 * postWidth,   pointHeight ),
                               T( -0.5 * postWidth,   postHeight - markerHeight),
                               T( -0.5 * markerWidth, postHeight - markerHeight),
                               T( -0.5 * markerWidth, postHeight ),
                               T(  0.5 * markerWidth, postHeight ),
                               T(  0.5 * markerWidth, postHeight - markerHeight),
                               T(  0.5 * postWidth,   postHeight - markerHeight),
                               T(  0.5 * postWidth,   pointHeight ) ] )
      path.closeSubpath();
      
      context?.setFillColor( UIColor(rgb:[141,2,31]).cgColor )
      context?.addPath(path)
      context?.fillPath()
      
      context?.textMatrix = CGAffineTransform(scaleX: 1.0, y:-1.0)
      
      let label = NSString(format: "%d", index)
      
      let attr = [
        NSForegroundColorAttributeName: UIColor.yellow,
        //        NSFontAttributeName: UIFont.preferredFont(forTextStyle: .caption2)
        NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12.0)
      ]
      
      let labelSize   = label.size(attributes: attr)
      let labelCenter = T( 0.0, postHeight - 0.5 * markerHeight )
      
      let labelOrigin = CGPoint( x: labelCenter.x - 0.5 * labelSize.width,
                                 y: labelCenter.y - 0.5 * labelSize.height + 0.5 * postSkew * imageWidth )
      let labelRect   = CGRect( origin: labelOrigin, size: labelSize )
      
      context?.concatenate(CGAffineTransform(a: 1.0, b: -postSkew, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0))
      label.draw(in: labelRect, withAttributes: attr)
      
      im = UIGraphicsGetImageFromCurrentImageContext()
      
      UIGraphicsEndImageContext()
      
      PostImages.images[index] = im
    }
    
    return im!
  }
}

// MARK: - PostAnnotation class

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
      self.image      = PostImages.get(waypoint.index!)
      updateTitle()
    }
  }
  
  init(_ wp:Waypoint, north:NorthType, units:BaseUnitType )
  {
    self.waypoint     = wp
    self.coordinate   = wp.location
    self.image        = PostImages.get(wp.index!)
    self.centerOffset = CGPoint(x:0.0, y:-0.5*imageHeight)
      
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
