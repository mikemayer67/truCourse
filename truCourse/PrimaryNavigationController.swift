//
//  NavigationControllerDelegate.swift
//  truCourse
//
//  Created by Mike Mayer on 2/24/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class PrimaryNavigationController : UINavigationController, UINavigationControllerDelegate
{
  override func viewDidLoad()
  {
    super.viewDidLoad()
    self.delegate = self
  }
  
  func closeOptions(_ vc:OptionsViewController, options:Options?)
  {    
    guard topViewController == vc else { return }
    
    popViewController(animated: true)
    
    if options == nil { return }
    
    guard topViewController is PrimaryViewController else { return }
    let pvc = topViewController as! PrimaryViewController
    pvc.options = options!
  }
  
  // MARK: - Navigation Controller Delegate
  
  func navigationController(_ navigationController: UINavigationController,
                            animationControllerFor operation: UINavigationControllerOperation,
                            from fromVC: UIViewController,
                            to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?
  {
    var animator : UIViewControllerAnimatedTransitioning?
    
    if ( toVC   is OptionsViewController && operation == .push ) ||
       ( fromVC is OptionsViewController && operation == .pop )
    {
      animator = OptionsViewAnimator(operation)
    }
    
    return animator
  }
}
