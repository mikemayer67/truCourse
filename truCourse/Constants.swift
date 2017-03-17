//
//  Constants.swift
//  truCourse
//
//  Created by Mike Mayer on 3/16/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation

class Constants
{
  static let earthEquatorialRadius = 6.3781370e+06 // meters
  static let earthPolarRadius      = 6.3567523e+06 // meters
  static let earthFlatteningFactor = 1.0 - earthPolarRadius/earthEquatorialRadius
  static let earthEccentricity     = sqrt(earthFlatteningFactor * (2.0-earthFlatteningFactor))
  
  static let deg                   = Double.pi / 180.0
}

enum NotificationName : String
{
  case locationAuthorizationChanged = "clLocUpdate"
}
