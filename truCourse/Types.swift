//
//  Types.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import UIKit

enum VisualizationType : Int
{
  case MapView = 0
  case BearingView = 1
  case LatLonView = 2
  
  func next() -> VisualizationType
  {
    switch self
    {
    case .MapView:     return .BearingView
    case .BearingView: return .LatLonView
    case .LatLonView:  return .MapView
    }
  }
  
  func prev() -> VisualizationType
  {
    switch self
    {
    case .MapView:     return .LatLonView
    case .BearingView: return .MapView
    case .LatLonView:  return .BearingView
    }
  }
}

protocol VisualizationView : class
{
  var visualizationType : VisualizationType { get }
}

enum NorthType : Int
{
  case True     = 0
  case Magnetic = 1
}

enum BaseUnitType : Int
{
  case Metric  = 0
  case English = 1
}
