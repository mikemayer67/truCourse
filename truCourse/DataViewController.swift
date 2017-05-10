//
//  DataViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 3/28/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit


enum DataViewType : Int  // values match Segmented Control
{
  case map = 0
  case bearing = 1
  case latlon = 2
  
  func next() -> DataViewType
  {
    switch self
    {
    case .map:     return .bearing
    case .bearing: return .latlon
    case .latlon:  return .map
    }
  }
  
  func prev() -> DataViewType
  {
    switch self
    {
    case .map:     return .latlon
    case .bearing: return .map
    case .latlon:  return .bearing
    }
  }
}

protocol DataViewController : class
{
  var viewType      : DataViewType { get }
  var hasSelection  : Bool         { get }
  
  var dataController : DataController { get set }
  var uiViewController : UIViewController { get }
  
  func applyOptions()
  func applyState(_ state:AppState)
  func updateRoute(_ route:Route)
  func updateCandidate(_ cand:Waypoint?)
}

