//
//  NavBarItemAnimator.swift
//  truCourse
//
//  Created by Mike Mayer on 2/24/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class NavBarItemAnimator: NSObject, UIViewControllerAnimatedTransitioning
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
  
  func animateTransition(using context: UIViewControllerContextTransitioning)
  {
    var anim : (()->Void)!

    let dst        = context.viewController(forKey: .to)!
    let dstView    = context.view(forKey: .to)!
    let srcView    = context.view(forKey: .from)!
    let container  = context.containerView
    let finalFrame = context.finalFrame(for:dst)
    
    dstView.frame  = finalFrame

    container.window?.backgroundColor = nav.toolbar?.barTintColor
    container.addSubview(dstView)
    
    if type == .push
    {
      dstView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
      dstView.layer.position    = finalFrame.origin
      dstView.transform         = dstView.transform.scaledBy(x: 1.0, y: 0.01)
      
      anim = { dstView.transform = .identity; self.nav.toolbar?.alpha = 0.0 }
    }
    else if type == .pop
    {
      container.addSubview(srcView)

      srcView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
      srcView.layer.position    = finalFrame.origin
      nav.toolbar?.alpha = 0.0

      anim = { srcView.transform = srcView.transform.scaledBy(x: 1.0, y: 0.01); self.nav.toolbar?.alpha = 1.0 }
    }
    
    UIView.animate(withDuration: duration, animations:anim)
    {
      (finished:Bool)->Void in
      context.completeTransition( !context.transitionWasCancelled )
    }
  }

}
