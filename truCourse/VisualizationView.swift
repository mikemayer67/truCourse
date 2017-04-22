//
//  VisualizationView.swift
//  truCourse
//
//  Created by Mike Mayer on 3/28/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

enum VisualizationType : Int
{
  case None = -1
  case MapView = 0
  case BearingView = 1
  case LatLonView = 2
  
  func next() -> VisualizationType
  {
    switch self
    {
    case .None:        return .None
    case .MapView:     return .BearingView
    case .BearingView: return .LatLonView
    case .LatLonView:  return .MapView
    }
  }
  
  func prev() -> VisualizationType
  {
    switch self
    {
    case .None:        return .None
    case .MapView:     return .LatLonView
    case .BearingView: return .MapView
    case .LatLonView:  return .BearingView
    }
  }
}

protocol VisualizationView : class
{  
  var _visualizationType : VisualizationType { get }
  var _hasSelection      : Bool              { get }
  
  func _applyOptions()
  func _applyState(_ state:AppState)
  func _updateRoute(_ route:Route)
  func _updateCandidate(_ cand:Waypoint?)
}

extension UIViewController
{
  var isVisualizationView : Bool
  {
    return self is VisualizationView
  }
  
  var visualizationType : VisualizationType
  {
    var rval = VisualizationType.None

    if let vv = self as? VisualizationView
    {
      rval = vv._visualizationType
    }
    
    return rval
  }
  
  var hasSelection : Bool
  {
    var rval = false
    
    if let vv = self as? VisualizationView
    {
      rval = vv._hasSelection
    }
    
    return rval

  }
  
  func applyOptions()
  {
    if let vv = self as? VisualizationView
    {
      vv._applyOptions()
    }
  }
  
  func applyState(_ state:AppState)
  {
    if let vv = self as? VisualizationView
    {
      vv._applyState(state)
    }
  }
  
  func updateRoute(_ route:Route)
  {
    if let vv = self as? VisualizationView
    {
      vv._updateRoute(route)
    }
  }
  
  func updateCandidate(_ cand:Waypoint?)
  {
    if let vv = self as? VisualizationView
    {
      vv._updateCandidate(cand)
    }
  }
}
