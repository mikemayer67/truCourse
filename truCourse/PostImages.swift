//
//  PostImages.swift
//  truCourse
//
//  Created by Mike Mayer on 5/12/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import CoreGraphics

/*********************************************
 
 Because of issues with drawing text, I am going to skip affine transforms to make the
 coordinate system more "natural".  Rather, I am using my own method to convert the
 coordinates I prefer to use (origin at bottom center of "broken post" with +y = up)
 to CoreGraphics coordinates (origin in upper-left with +y down).
 
 The first graphic is used within the Map view.  In addition to changing the
 coordinate system, I will also apply a skew to the sign.
 
       |<-marker width-->|
 
 ---   +-----------------+   ---
  ^    |                 |    ^
  |    |                 |    |
  |    |                 |    marker height
  |    |                 |    |
  |    |                 |    v
  |    +-----+     +-----+   ---
  |          |     |
  |          |     |
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
 
 
 The second graphic is used with the List view.  This one is NOT skewed, but will contain
 a shadow.
 
       |<-marker width->|
 
 ---   +----------------+   ---               x = cg = x + image_width/2
  ^    |                |    ^                y = cg = image_height - shadow_pad - y
  |    |                |    |
 post  |                |    marker height        +-                                          -+
height |                |    |                    |       1                     0            0 |
  |    |                |    v                T = |       0                    -1            0 |
  |    +-----+    +-----+   ---                   | image_width/2   image_height-shadow_pad  1 +
  |          |    |                               +-                                          -+
  v          \/\/\/          } point height
 ---
             |<-->|
           post width
 
 ***********************************************/


class PostImage
{
  class Library
  {
    private var images = [Int:PostImage]()
    
    subscript(index:Int) -> PostImage
    {
      var pi = images[index]
      if pi == nil
      {
        pi = PostImage(index)
        images[index] = pi
      }
      return pi!
    }
  }
  
  static var library = Library()
  
  private(set) var image : UIImage!
  
  let postWidth    : CGFloat =  4.0
  let postHeight   : CGFloat = 34.0
  let pointHeight  : CGFloat =  6.0
  let markerWidth  : CGFloat = 18.0
  let markerHeight : CGFloat = 15.0
  
  let postSkew     : CGFloat =  0.2
  
  let imageWidth   : CGFloat
  let imageHeight  : CGFloat
  
  var centerOffset : CGPoint { return CGPoint(x:0.0, y:-0.5*imageHeight) }
  
  fileprivate func T(_ x:CGFloat, _ y:CGFloat) -> CGPoint
  {
    let cgx = x + 0.5*imageWidth
    let cgy = imageHeight - ( y + postSkew * x )
    
    return CGPoint(x:cgx, y:cgy)
  }
  
  fileprivate init(_ index:Int)
  {
    imageWidth  = CGFloat(markerWidth)
    imageHeight = CGFloat(postHeight) + 0.5 * postSkew * CGFloat(postWidth)
    
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
      NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12.0)
    ]
    
    let labelSize   = label.size(attributes: attr)
    let labelCenter = T( 0.0, postHeight - 0.5 * markerHeight )
    
    let labelOffset = labelSize.applying(CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: -postSkew*imageWidth))
    
    let labelOrigin = labelCenter.offset(by: labelOffset.scaled(by: -0.5))
    let labelRect   = CGRect( origin: labelOrigin, size: labelSize )
    
    context?.concatenate(CGAffineTransform(a: 1.0, b: -postSkew, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0))
    label.draw(in: labelRect, withAttributes: attr)
    
    image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
  }
}

class PostIcon
{
  class Library
  {
    private var icons = [Int:PostIcon]()
    
    subscript(index:Int) -> PostIcon
    {
      var pi = icons[index]
      if pi == nil
      {
        pi = PostIcon(index)
        icons[index] = pi
      }
      return pi!
    }
  }
  
  static var library = Library()
  
  private(set) var image : UIImage!
  
  let postWidth    : CGFloat = 12.0
  let postHeight   : CGFloat = 30.0
  let markerWidth  : CGFloat = 30.0
  let markerHeight : CGFloat = 20.0
  let pointHeight  : CGFloat =  4.0
  let shadowPad    : CGFloat =  7.0
  let shadowOffset : CGSize  = CGSize( width:1.5, height:1.0)
  let shadowBlur   : CGFloat =  7.0
  
  let imageWidth   : CGFloat
  let imageHeight  : CGFloat
  
  fileprivate func T(_ x:CGFloat, _ y:CGFloat) -> CGPoint
  {
    let cgx = x + 0.5*imageWidth
    let cgy = imageHeight - shadowPad - y
    
    return CGPoint(x:cgx, y:cgy)
  }
  
  fileprivate init(_ index:Int)
  {
    imageWidth  = CGFloat(markerWidth) + 2.0 * shadowPad
    imageHeight = CGFloat(postHeight) + 2.0 * shadowPad
    
    UIGraphicsBeginImageContext(CGSize(width:imageWidth, height:imageHeight))
    let context = UIGraphicsGetCurrentContext();
    
    let pointWidth = postWidth / 3.0
    
    let path = CGMutablePath()
    path.addLines(between: [ T(  0.0,               0.0 ),
                             T( -0.5 * pointWidth,  pointHeight ),
                             T( -1.0 * pointWidth,  0.0 ),
                             T( -0.5 * postWidth,   pointHeight ),
                             T( -0.5 * postWidth,   postHeight - markerHeight),
                             T( -0.5 * markerWidth, postHeight - markerHeight),
                             T( -0.5 * markerWidth, postHeight ),
                             T(  0.5 * markerWidth, postHeight ),
                             T(  0.5 * markerWidth, postHeight - markerHeight),
                             T(  0.5 * postWidth,   postHeight - markerHeight),
                             T(  0.5 * postWidth,   pointHeight ),
                             T(  1.0 * pointWidth,  0.0 ),
                             T(  0.5 * pointWidth,  pointHeight ) ] )
    path.closeSubpath();
    
    context?.setFillColor( UIColor(rgb:[141,2,31]).cgColor )
    context?.setShadow(offset: shadowOffset, blur: shadowBlur)
    context?.addPath(path)
    context?.fillPath()
    
    context?.textMatrix = CGAffineTransform(scaleX: 1.0, y:-1.0)
    
    let label = NSString(format: "%d", index)
    
    let attr = [
      NSForegroundColorAttributeName: UIColor.yellow,
      NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16.0)
    ]
    
    let labelSize   = label.size(attributes: attr)
    let labelCenter = T( 0.0, postHeight - 0.5 * markerHeight )
    
    let labelOrigin = labelCenter.offset(by: labelSize.scaled(by: -0.5))
    let labelRect   = CGRect( origin: labelOrigin, size: labelSize )
    
    label.draw(in: labelRect, withAttributes: attr)
    
    image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
  }
}
