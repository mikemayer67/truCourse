//
//  NavigationControllerDelegate.swift
//  truCourse
//
//  Created by Mike Mayer on 2/24/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class MainController : UINavigationController, UINavigationControllerDelegate
{
  weak var dataViewController : DataViewController!
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    self.delegate = self    
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
      animator = OptionsViewAnimator(self, operator: operation)
    }
    
    return animator
  }
  
  func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool)
  {
    if let ovc = viewController as? OptionsViewController
    {
      ovc.delegate = dataViewController
      ovc.checkState()
    }
  }
}
