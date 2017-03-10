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
  
  override func unwind(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController)
  {
    super.unwind(for: unwindSegue, towardsViewController: subsequentVC)
    print("unwind PNC toward \(subsequentVC)\n  \(unwindSegue.source) --> \(unwindSegue.destination)")
  }
}
