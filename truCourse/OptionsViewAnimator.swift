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
    if      self.type == .push { showOptions(using:transitionContext) }
    else if self.type == .pop  { hideOptions(using:transitionContext) }
  }
  
  func showOptions(using context: UIViewControllerContextTransitioning)
  {
    let src = context.viewController(forKey: .from)!
    let dst = context.viewController(forKey: .to  )!
    
    let srcView = src.view!
    let dstView = dst.view!
    
    let barHeight = src.navigationController?.toolbar.frame.height ?? 0.0
    
    let origin   = srcView.frame.origin
    
    let srcSize  = srcView.frame.size
    var dstSize  = srcSize; dstSize.height += barHeight
    
    dstView.frame = CGRect(origin:origin, size:dstSize)
    
    dstView.layer.position = origin
    dstView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    dstView.transform = dstView.transform.scaledBy(x: 1.0, y: 0.01)
    
    UIApplication.shared.keyWindow!.insertSubview(dstView, aboveSubview: srcView)
    
    UIView.animate(withDuration: 0.35, animations:
      {
        dstView.transform = .identity
      }
    ) { (finished)->Void in context.completeTransition( !context.transitionWasCancelled ) }
  }
  
  func hideOptions(using context: UIViewControllerContextTransitioning)
  {
    let src = context.viewController(forKey: .from)!
    let dst = context.viewController(forKey: .to  )!
    
    let srcView = src.view!
    let dstView = dst.view!
    
    srcView.layer.position = srcView.frame.origin
    srcView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    srcView.transform = .identity
    
    UIApplication.shared.keyWindow!.insertSubview(dstView, belowSubview: srcView)
    
    UIView.animate(withDuration: 0.35, animations:
      {
        srcView.transform = srcView.transform.scaledBy(x: 1.0, y: 0.01)
      }
    ) { (finished)->Void in context.completeTransition( !context.transitionWasCancelled ) }
  }

}
