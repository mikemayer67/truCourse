//
//  DataViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreLocation

class DataViewController :
  UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate,
  OptionViewControllerDelegate
{
  @IBOutlet var viewTypeControl : UISegmentedControl!
  @IBOutlet var dataController  : DataController!
  
  @IBOutlet var onOffBarItem    : UIBarButtonItem!
  @IBOutlet var startBarItem    : UIBarButtonItem!
  @IBOutlet var pauseBarItem    : UIBarButtonItem!
  @IBOutlet var recordBarItem   : UIBarButtonItem!
  @IBOutlet var saveBarItem     : UIBarButtonItem!
  @IBOutlet var shareBarItem    : UIBarButtonItem!
  
  var dataControllers = [VisualizationType:UIViewController]()
  var currentViewType = VisualizationType.MapView
  
  private var activeToolbar        = true
  private var activeToolbarItems   : [UIBarButtonItem]!
  private var inactiveToolbarItems : [UIBarButtonItem]!
    
  private(set) var route : Route?
        
  var options = Options()
  {
    didSet
    {
      options.updateDefaults()
      Options.commit()
      applyOptions()
    }
  }
    
  override func viewDidLoad()
  {
    super.viewDidLoad()
        
    let sb = self.storyboard!
    
    dataControllers[.MapView]     = sb.instantiateViewController(withIdentifier: "mapViewController")
    dataControllers[.BearingView] = sb.instantiateViewController(withIdentifier: "bearingViewController")
    dataControllers[.LatLonView]  = sb.instantiateViewController(withIdentifier: "latLonViewController")
    
    self.navigationController!.navigationBar.tintColor = UIColor.white
    (self.navigationController as! MainController).dataViewController = self
    
    self.dataSource = self
    self.delegate = self
    self.setViewControllers([dataControllers[currentViewType]!], direction: .forward, animated: false, completion: nil)
    
    activeToolbarItems = self.toolbarItems
    
    inactiveToolbarItems = [
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      UIBarButtonItem(title: "location services diabled", style: .plain, target: nil, action: nil),
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    ]
    inactiveToolbarItems[1].tintColor = UIColor.yellow
    
    applyOptions()
    
    dataController.updateState(.Start)
  }
  
  func applyOptions()
  {
    for (_,controller) in dataControllers { (controller as! VisualizationView).applyOptions(options) }
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
  
  // MARK: - OptionViewController Delegate
  
  func optionsDiffer(from candidateOptions: Options) -> Bool
  {
    return candidateOptions.differ(from: self.options)
  }
  
  func updateOptions(_ newOptions: Options)
  {
    self.options = newOptions
    
    dataController.updateOptions()
  }
  
  // MARK: - Toolbar handler
  
  func updateState(_ state:AppState)
  {    
    switch state
    {
    case .Disabled:
      if activeToolbar  { self.setToolbarItems(inactiveToolbarItems, animated: true) }
      activeToolbar = false
    default:
      if !activeToolbar { self.setToolbarItems(activeToolbarItems, animated: true) }
      activeToolbar = true
    }
  }
}
