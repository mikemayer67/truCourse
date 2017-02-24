//
//  NavigationControllerDelegate.swift
//  truCourse
//
//  Created by Mike Mayer on 2/24/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class PrimaryNavigationController : UINavigationController
{
  func closeOptions(_ vc:OptionsViewController, options:Options?)
  {    
    guard topViewController == vc else { return }
    
    popViewController(animated: true)
    
    if options == nil { return }
    
    guard topViewController is PrimaryViewController else { return }
    let pvc = topViewController as! PrimaryViewController
    pvc.options = options!
  }
}
