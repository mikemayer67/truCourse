//
//  RenumberViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 4/26/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

protocol RenumberViewDelegate : UIPickerViewDelegate, UIPickerViewDataSource
{
  func title(for view:RenumberViewController) -> String?
  func renumberView(_ view:RenumberViewController, didSelect row:Int)
}


class RenumberViewController: UIViewController, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate
{
  @IBOutlet weak var pickerView: UIPickerView!
  @IBOutlet weak var titleLabel: UILabel!
  
  var delegate     : RenumberViewDelegate?
  var isPresenting : Bool?
  
  let transitionDuration : TimeInterval = 0.25
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    pickerView.delegate   = delegate
    pickerView.dataSource = delegate
  }
  
  override func viewWillAppear(_ animated: Bool)
  {
    titleLabel.text = delegate?.title(for:self)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func handle_cancel(_ sender: UIButton)
  {
    self.dismiss(animated: true)
  }
  
  @IBAction func handle_done(_ sender: UIButton)
  {
    let index = pickerView.selectedRow(inComponent: 0)
    delegate?.renumberView(self, didSelect: index)
    
    self.dismiss(animated: true)
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
