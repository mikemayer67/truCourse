//
//  MyPageViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import CoreGraphics

class PrimaryViewController :
  UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
  @IBOutlet var viewTypeControl : UISegmentedControl!
  
  var dataControllers = [VisualizationType:UIViewController]()
  var currentViewType = VisualizationType.MapView
  
  var options = Options()
  {
    didSet
    {
      print("PVC Options updated: \(options)")
      options.updateDefaults()
      Options.commit()
    }
  }
    
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    let sb = self.storyboard!
    
    dataControllers[.MapView]     = sb.instantiateViewController(withIdentifier: "mapViewController")
    dataControllers[.BearingView] = sb.instantiateViewController(withIdentifier: "bearingViewController")
    dataControllers[.LatLonView]  = sb.instantiateViewController(withIdentifier: "latLonViewController")
    
    self.navigationController?.navigationBar.tintColor = UIColor.white
    
    self.dataSource = self
    self.delegate = self
    self.setViewControllers([dataControllers[currentViewType]!], direction: .forward, animated: false, completion: nil)
  }
  
  // MARK: - Page View Data Source
  
  @IBAction func setCurrentViewType(_ sender: UISegmentedControl)
  {
    let nextType = VisualizationType(rawValue: sender.selectedSegmentIndex)!
    let delta = nextType.rawValue - currentViewType.rawValue

    if delta != 0
    {
      self.setViewControllers([dataControllers[nextType]!],
                              direction: ( (delta == 1)||(delta == -2) ? .forward : .reverse),
                              animated: true)
      
      self.setCurrentView(nextType)
    }
  }
  
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController ) -> UIViewController?
  {
    let visType = viewController as! VisualizationView
    return dataControllers[visType.visualizationType.next()]
  }
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController ) -> UIViewController?
  {
    let visType = viewController as! VisualizationView
    return dataControllers[visType.visualizationType.prev()]
  }
  
  @discardableResult func setCurrentView(_ type : VisualizationType) -> Bool
  {
    guard currentViewType != type else { return false }
    currentViewType = type
    return true
  }
  
  // MARK: - Page View Delegate
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          willTransitionTo pendingViewControllers: [UIViewController])
  {
    let c = pendingViewControllers[0]
    
    let t = c as! VisualizationView
    
    print("will transistion to: \(t.visualizationType)")
  }
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool)
  {
    if finished && completed
    {
      let newVC   = self.viewControllers![0]
      let visType = newVC as! VisualizationView
      let newType = visType.visualizationType
      
      if self.setCurrentView(newType)
      {
        self.viewTypeControl.selectedSegmentIndex = newType.rawValue
      }
    }
  }
}
