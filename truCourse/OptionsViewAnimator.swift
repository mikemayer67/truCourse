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
  var nav  : UINavigationController
  var type : UINavigationControllerOperation
  
  let duration = 0.35
  
  init(_ nav:UINavigationController, operator type:UINavigationControllerOperation)
  {
    self.nav  = nav
    self.type = type
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
  {
    return self.duration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
  {
    switch type
    {
    case .push: showOptions(using: transitionContext)
    case .pop:  hideOptions(using: transitionContext)
    default:    break
    }
  }
  
  func showOptions(using context: UIViewControllerContextTransitioning)
  {
    let dst        = context.viewController(forKey: .to)!
    let dstView    = context.view(forKey: .to)!
    
    let finalFrame = context.finalFrame(for:dst)
    
    let toolbar    = nav.toolbar
    
    dstView.frame             = finalFrame
    dstView.layer.position    = finalFrame.origin
    dstView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    dstView.transform         = dstView.transform.scaledBy(x: 1.0, y: 0.01)
    
    let container = context.containerView
    container.addSubview(dstView)
    
    container.window?.backgroundColor = toolbar?.barTintColor
    
    UIView.animate(withDuration: self.duration, animations:
      {
        dstView.transform = .identity
        toolbar?.alpha = 0.0
      } )
      {
        (finished)->Void in
        context.completeTransition( !context.transitionWasCancelled )
      }
  }
 
  func hideOptions(using context: UIViewControllerContextTransitioning)
  {
    let dst        = context.viewController(forKey: .to)!
    let srcView    = context.view(forKey: .from)!
    let dstView    = context.view(forKey: .to)!
    let finalFrame = context.finalFrame(for:dst)
    
    let toolbar    = nav.toolbar
    
    dstView.frame  = finalFrame
    srcView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    
    let container = context.containerView
    container.addSubview(dstView)
    container.addSubview(srcView)
    
    toolbar?.alpha = 0.0

    UIView.animate(withDuration: 0.35, animations:
      {
        srcView.transform = srcView.transform.scaledBy(x: 1.0, y: 0.01)
        toolbar?.alpha = 1.0
      } )
      {
        (finished)->Void in
        context.completeTransition( !context.transitionWasCancelled )
      }
  }
}
