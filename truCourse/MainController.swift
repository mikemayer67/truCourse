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
  weak var dataPageController : DataPageController!
  
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

    else if ( toVC   is RoutesViewController && operation == .push ) ||
            ( fromVC is RoutesViewController && operation == .pop )
    {
      animator = RoutesViewAnimator(self, operator: operation)
    }
    
    return animator
  }
  
  func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool)
  {
    if let ovc = viewController as? OptionsViewController
    {
      ovc.delegate = dataPageController
      ovc.checkState()
    }
    else if let rvc = viewController as? RoutesViewController
    {
      rvc.delegate = self.dataPageController.dataController
    }
  }
}
