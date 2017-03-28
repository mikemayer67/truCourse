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
  
  var dataControllers = [VisualizationType:UIViewController]()
  var currentViewType = VisualizationType.MapView
  
  private var activeToolbar        = true
  private var activeToolbarItems   : [UIBarButtonItem]!
  private var inactiveToolbarItems : [UIBarButtonItem]!
  private var onBarItem            : UIBarButtonItem!
  private var offBarItem           : UIBarButtonItem!
  private var startBarItem         : UIBarButtonItem!
  private var stopBarItem          : UIBarButtonItem!
  private var recordBarItem        : UIBarButtonItem!
  private var trashBarItem         : UIBarButtonItem!
  private var shareBarItem         : UIBarButtonItem!
      
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
    
    onBarItem     = UIBarButtonItem(image: UIImage(named:"Off_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleOn(_:)))
    offBarItem    = UIBarButtonItem(image: UIImage(named:"On_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleOff(_:)))
    startBarItem  = UIBarButtonItem(image: UIImage(named:"Play_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleStart(_:)))
    stopBarItem   = UIBarButtonItem(image: UIImage(named:"Pause_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handlePause(_:)))
    recordBarItem = UIBarButtonItem(image: UIImage(named:"Pin_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleRecord(_:)))
    trashBarItem  = UIBarButtonItem(image: UIImage(named:"Trash_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleTrash(_:)))
    shareBarItem  = UIBarButtonItem(image: UIImage(named:"Upload_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleShare(_:)))
    
    let onOffTint = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
    onBarItem.tintColor  = onOffTint
    offBarItem.tintColor = onOffTint
    
    startBarItem.tintColor  = UIColor.white
    stopBarItem.tintColor   = UIColor.white
    recordBarItem.tintColor = UIColor.white
    trashBarItem.tintColor  = UIColor.white
    shareBarItem.tintColor  = UIColor.white
    
    activeToolbarItems = [
      /*0*/ onBarItem,
      /*1*/ startBarItem,
      /*2*/ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      /*3*/ recordBarItem,
      /*4*/ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      /*5*/ shareBarItem
    ]
    
    let disabledBarItem = UIBarButtonItem(title: "location services diabled", style: .plain, target: nil, action: nil)
    
    disabledBarItem.tintColor = UIColor.yellow

    inactiveToolbarItems = [
      disabledBarItem,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      shareBarItem
    ]
    
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
  
  func updateState()
  {
    let state = dataController.state
    let dvc   = dataControllers[currentViewType] as! VisualizationView
    
    switch state
    {
    case .Uninitialized: break
    case .Disabled:      break
      
    case .Paused:
      print("Paused state")
      activeToolbarItems[0] = onBarItem
      activeToolbarItems[1].isEnabled = false
      activeToolbarItems[3].isEnabled = false
      
    case .Idle:
      print("Idle state")
      activeToolbarItems[0]  = offBarItem
      activeToolbarItems[1]  = startBarItem
      activeToolbarItems[3]  = trashBarItem
      trashBarItem.isEnabled = dvc.hasSelection
      
    case .Inserting:
      print("Inserting state")
      fallthrough
      
    case .Editing:
      print("Editing state (if not inserting)")
      activeToolbarItems[0]   = offBarItem
      activeToolbarItems[1]   = stopBarItem
      activeToolbarItems[3]   = recordBarItem
      recordBarItem.isEnabled = dataController.okToRecord
    }

    shareBarItem.isEnabled = ( dataController.currentRoute?.count ?? 0 ) > 1
    
    let toolbar = navigationController?.toolbar
    switch state
    {
    case .Disabled: toolbar?.setItems(inactiveToolbarItems, animated: true)
    default:        toolbar?.setItems(  activeToolbarItems, animated: true)
    }
  }
  
  func handleOn(_ sender: UIBarButtonItem)
  {
    print("DVC handleOn")
    dataController.updateState(.Enabled(true))
  }
  
  func handleOff(_ sender: UIBarButtonItem)
  {
    print("DVC handleOff")
    dataController.updateState(.Enabled(false))
  }
  
  func handleStart(_ sender: UIBarButtonItem)
  {
    print("DVC handleStart")
  }
  
  func handlePause(_ sender: UIBarButtonItem)
  {
    print("DVC handlePause")
  }
  
  func handleRecord(_ sender: UIBarButtonItem)
  {
    print("DVC handleRecord")
  }
  
  func handleTrash(_ sender: UIBarButtonItem)
  {
    print("DVC handleTrash")
  }
  
  func handleShare(_ sender: UIBarButtonItem)
  {
    print("DVC handleShare")
  }
  
}
