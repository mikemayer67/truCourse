//
//  OptionsViewAnimator.swift
//  truCourse
//
//  Created by Mike Mayer on 2/24/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class OptionsViewAnimator: NSObject, UIViewControllerAnimatedTransitioning,UIViewControllerTransitioningDelegate
{
  fileprivate var isPresenting = true
  fileprivate var isNavPushPop = false
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
  {
    return 0.35
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
  {
    if isPresenting { showOptions(using:transitionContext) }
    else            { hideOptions(using:transitionContext) }
  }
  
  func showOptions(using context: UIViewControllerContextTransitioning)
  {
    let src       = context.viewController(forKey: .from)!
    let dstView   = context.view(forKey: .to)!
    let dstEnd    = UIApplication.shared.keyWindow?.bounds
    
    dstView.frame = dstEnd!
    dstView.layer.position = (dstEnd?.origin)!
    dstView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    dstView.transform = dstView.transform.scaledBy(x: 1.0, y: 0.01)
    
    if isNavPushPop
    {
      if let parent = src.parent as? UINavigationController
      {
        parent.view.addSubview(dstView)
      }
    }
    else
    {
      let container = context.containerView
      container.addSubview(dstView)
    }
    
    UIView.animate(withDuration: 0.35, animations: { dstView.transform = .identity } )
    {
      (finished)->Void in
      context.completeTransition( !context.transitionWasCancelled )
    }
  }
  
  func hideOptions(using context: UIViewControllerContextTransitioning)
  {
    let src       = context.viewController(forKey: .from)!
    let srcView   = context.view(forKey: .from)!
    let dstView   = context.view(forKey: .to)!
    
    let container = context.containerView
    container.addSubview(dstView)
    
    if isNavPushPop
    {
      if let parent = src.parent as? UINavigationController
      {
        parent.view.insertSubview(dstView, belowSubview: parent.navigationBar)
      }
    }
    else
    {
      container.addSubview(srcView)
    }
    
    srcView.layer.anchorPoint = CGPoint(x:0.0,y:0.0)
    
    UIView.animate(withDuration: 0.35, animations:
      { srcView.transform = srcView.transform.scaledBy(x: 1.0, y: 0.01) } )
    {
      (finished)->Void in
      if self.isNavPushPop
      {
        srcView.removeFromSuperview()
      }
      
      context.completeTransition( !context.transitionWasCancelled )
    }
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
  {
    isPresenting = false
    return self
  }
  
  
  func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning?
  {
    isPresenting = true
    return self
  }
}

extension OptionsViewAnimator: UINavigationControllerDelegate
{
  func navigationController(_ navigationController: UINavigationController,
                            animationControllerFor operation: UINavigationControllerOperation,
                            from fromVC: UIViewController,
                            to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
  {
    isNavPushPop = true
    self.isPresenting = operation == .push
    return self
  }
}

/*
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
 */
