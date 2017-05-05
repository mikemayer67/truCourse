//
//  PopupViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 5/3/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate
{
  
  var isPresenting : Bool?
  
  let transitionDuration : TimeInterval = 0.25


    override func viewDidLoad()
    {
      super.viewDidLoad()
      
      self.modalPresentationStyle = .overCurrentContext
      self.modalPresentationCapturesStatusBarAppearance = true
      self.transitioningDelegate = self
    }

  // MARK: - Transitioning Delegate
  
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
  {
    isPresenting = true
    return self
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
  {
    isPresenting = false
    return self
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
  {
    return transitionDuration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
  {
    let fromVC   = transitionContext.viewController(forKey: .from)!
    let toVC     = transitionContext.viewController(forKey: .to)!
    let cv       = transitionContext.containerView
    let fromView = fromVC.view!
    let toView   = toVC.view!
    
    if self.isPresenting!
    {
      cv.addSubview(toView)
      toView.frame = cv.frame
      toView.alpha = 0.0
      
      toView.transform = CGAffineTransform(scaleX: 1.0, y: 0.01)
      
      UIView.animate(withDuration: transitionDuration, animations:
        {
          toView.alpha = 1.0
          toView.transform = CGAffineTransform.identity
      },
                     completion: { _ in transitionContext.completeTransition(true) }
      )
    }
    else
    {
      UIView.animate(withDuration: transitionDuration, animations:
        {
          fromView.alpha = 0.0
          fromView.transform = CGAffineTransform(scaleX: 1.0, y: 0.01)
      },
                     completion: { _ in transitionContext.completeTransition(true) }
      )
    }
  }
  
  

}
