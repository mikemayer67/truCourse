//
//  Extensions.swift
//  truCourse
//
//  Created by Mike Mayer on 4/20/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

extension CLLocationDegrees
{
  init(_ deg:Int, _ min:Int = 0, _ sec:Int = 0)
  {
    let ms = Double(min) + Double(sec)/60.0
    if deg < 0 { self = Double(deg) - ms }
    else       { self = Double(deg) + ms }
  }
  
  var dms : String
  {
    let neg = self < 0.0
    var sec   = Int(3600.0 * (neg ? -self : self) + 0.5)
    var min = Int(sec/60)
    sec %= 60
    var deg = Int(min/60)
    min %= 60
    if neg { deg = -deg }
    let rval = String(format: "%4dº%02d'%02d\"", deg, min, sec)
    return rval
  }
}

extension UIColor
{
  convenience init(rgb:[Int], alpha:CGFloat = 1.0)
  {
    guard rgb.count == 3 else { fatalError("UIColor(rgb:[Int]) requires an array of 3 values") }
    
    let r = CGFloat(rgb[0]) / 255.0
    let g = CGFloat(rgb[1]) / 255.0
    let b = CGFloat(rgb[2]) / 255.0
    
    self.init(red:r, green:g, blue:b, alpha:alpha)
  }
}

extension UIView
{
  func remove(_ filter: (UIGestureRecognizer)->Bool)
  {
    if let grs = self.gestureRecognizers
    {
      grs.forEach { if filter($0) { self.removeGestureRecognizer($0) } }
    }
    
    self.subviews.forEach { $0.remove(filter) }
  }
}
