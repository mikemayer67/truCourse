//
//  VisualizationView.swift
//  truCourse
//
//  Created by Mike Mayer on 3/28/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

protocol VisualizationView : class
{
  var _visualizationType : VisualizationType { get }
  var _hasSelection      : Bool              { get }
  
  func _applyOptions(_ options:Options)
  func _applyState(_ state:AppState)
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
  
  func applyOptions(_ options:Options)
  {
    if let vv = self as? VisualizationView
    {
      vv._applyOptions(options)
    }
  }
  
  func applyState(_ state:AppState)
  {
    if let vv = self as? VisualizationView
    {
      vv._applyState(state)
    }
  }
}
