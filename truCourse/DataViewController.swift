//
//  DataViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 3/28/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

protocol DataViewController : class
{
  var ui               : UIViewController { get }
  var hasSelection     : Bool             { get }
  var tag              : Int              { get }
  
  var dataController   : DataController!  { get set }
  
  func applyOptions()
  func applyState(_ state:AppState)
  func updateRoute(_ route:Route)
  func updateCandidate(_ cand:Waypoint?)
}

extension DataViewController
{
  var tag : Int              { return (self as! UIViewController).view.tag }
  var ui  : UIViewController { return self as! UIViewController }
}

