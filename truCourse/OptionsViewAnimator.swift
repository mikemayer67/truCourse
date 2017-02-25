//
//  OptionsViewAnimator.swift
//  truCourse
//
//  Created by Mike Mayer on 2/24/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class OptionsViewAnimator: NSObject, UIViewControllerAnimatedTransitioning
{
  var type : UINavigationControllerOperation
  
  init(_ type : UINavigationControllerOperation)
  {
    self.type = type
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
  {
    return 0.35
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
  {
    
  }
}
