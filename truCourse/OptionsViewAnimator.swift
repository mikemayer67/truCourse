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
  
  let duration = 0.35
  
  init(operator type:UINavigationControllerOperation)
  {
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
    let src        = context.viewController(forKey: .from)!
    let srcView    = context.view(forKey: .from)!
    let dstView    = context.view(forKey: .to)!
    
    let nav        = src.navigationController
    let toolbar    = nav?.toolbar

    let screen     = UIScreen.main.bounds
    let origin     = srcView.frame.origin
    var dstSize    = srcView.frame.size
    
    dstSize.height = screen.height - origin.y
    
    dstView.frame = CGRect(origin: origin, size: dstSize)
    dstView.layer.position = origin
    dstView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    dstView.transform = dstView.transform.scaledBy(x: 1.0, y: 0.01)
    
    let container = context.containerView
    container.addSubview(dstView)
    
    srcView.window?.backgroundColor = toolbar?.barTintColor
    nav?.setToolbarHidden(true, animated: false)
    
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
    let src        = context.viewController(forKey: .from)!
    let srcView    = context.view(forKey: .from)!
    let dstView    = context.view(forKey: .to)!
    
    let screen     = UIScreen.main.bounds
    let origin     = srcView.frame.origin
    var dstSize    = srcView.frame.size
    
    let nav        = src.navigationController
    let toolbar    = nav?.toolbar
    let barHeight  = toolbar?.frame.height ?? 0.0
    
    dstSize.height = screen.height - (origin.y + barHeight)
    
    dstView.frame = CGRect(origin:origin, size:dstSize)
    
    let container = context.containerView
    container.addSubview(dstView)
    container.addSubview(srcView)
    
    srcView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    nav?.setToolbarHidden(false, animated: false)
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
