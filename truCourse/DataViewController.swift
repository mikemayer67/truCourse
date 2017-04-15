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
  
  var visualizationControllers = [VisualizationType:UIViewController]()
  var currentView : UIViewController!
  
  private var activeToolbar        = true
  private var activeToolbarItems   : [UIBarButtonItem]!
  private var inactiveToolbarItems : [UIBarButtonItem]!
  private var onBarItem            : UIBarButtonItem!
  private var offBarItem           : UIBarButtonItem!
  private var startBarItem         : UIBarButtonItem!
  private var stopBarItem          : UIBarButtonItem!
  private var recordBarItem        : UIBarButtonItem!
  private var undoBarItem          : UIBarButtonItem!
  private var shareBarItem         : UIBarButtonItem!
  
  private var lastRecordTime       : Date?
      
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
    
    visualizationControllers[.MapView]     = sb.instantiateViewController(withIdentifier: "mapViewController")
    visualizationControllers[.BearingView] = sb.instantiateViewController(withIdentifier: "bearingViewController")
    visualizationControllers[.LatLonView]  = sb.instantiateViewController(withIdentifier: "latLonViewController")
    
    currentView = visualizationControllers[VisualizationType.MapView]
    
    self.navigationController!.navigationBar.tintColor = UIColor.white
    (self.navigationController as! MainController).dataViewController = self
    
    self.dataSource = self
    self.delegate = self
    self.setViewControllers([currentView], direction: .forward, animated: false, completion: nil)
    
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
    undoBarItem   = UIBarButtonItem(image: UIImage(named:"Undo_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleUndo(_:)))
    shareBarItem  = UIBarButtonItem(image: UIImage(named:"Upload_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleShare(_:)))
    
    let onOffTint = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
    onBarItem.tintColor  = onOffTint
    offBarItem.tintColor = onOffTint
    
    startBarItem.tintColor  = UIColor.white
    stopBarItem.tintColor   = UIColor.white
    recordBarItem.tintColor = UIColor.white
    undoBarItem.tintColor   = UIColor.white
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
  
  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    
    let toolbar = navigationController?.toolbar
    switch dataController.state
    {
    case .Disabled: toolbar?.setItems(inactiveToolbarItems, animated: true)
    default:        toolbar?.setItems(  activeToolbarItems, animated: true)
    }
  }
  
  func applyOptions()
  {
    for (_,controller) in visualizationControllers { controller.applyOptions(options) }
  }

  // MARK: - Page View Data Source
  
  @IBAction func setCurrentViewType(_ sender: UISegmentedControl)
  {
    let nextType = VisualizationType(rawValue: sender.selectedSegmentIndex)!
    let nextVC   = visualizationControllers[nextType]!
    
    if( nextVC !== currentView)
    {
      let delta = nextType.rawValue - currentView.visualizationType.rawValue

      self.setViewControllers([nextVC],
                              direction: ( (delta == 1)||(delta == -2) ? .forward : .reverse),
                              animated: true)
      
      currentView = nextVC
    }
  }
  
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController ) -> UIViewController?
  {
    return visualizationControllers[viewController.visualizationType.next()]
  }
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController ) -> UIViewController?
  {
    return visualizationControllers[viewController.visualizationType.prev()]
  }
  
  // MARK: - Page View Delegate
  
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool)
  {
    if finished && completed
    {
      currentView  = viewControllers![0]
      viewTypeControl.selectedSegmentIndex = currentView.visualizationType.rawValue
    }
  }

  // MARK: - Motion Handlers
  
  override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
  {
    switch motion
    {
    case .motionShake:
      if options.canShakeUndo
      {
        if let t = lastRecordTime, let maxTime = options.shakeUndoTimeout
        {
          if Date().timeIntervalSince(t) <= maxTime
          {
            dataController.undoRecord()
          }
        }
      }
    default:
      break
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
  
  func applyState()
  {
    let state = dataController.state
    
    switch state
    {
    case .Uninitialized: break
    case .Disabled:      break
      
    case .Paused:
      activeToolbarItems[0] = onBarItem
      activeToolbarItems[1].isEnabled = false
      activeToolbarItems[3].isEnabled = false
      
    case .Idle:
      activeToolbarItems[0]  = offBarItem
      activeToolbarItems[1]  = startBarItem
      activeToolbarItems[3]  = undoBarItem
      startBarItem.isEnabled = true
      undoBarItem.isEnabled  = dataController.canUndo
      
    case .Inserting:
      fallthrough
      
    case .Editing:
      activeToolbarItems[0]   = offBarItem
      activeToolbarItems[1]   = stopBarItem
      activeToolbarItems[3]   = recordBarItem
      stopBarItem.isEnabled   = true
      recordBarItem.isEnabled = dataController.okToRecord
    }

    shareBarItem.isEnabled = dataController.canShare
    
    let toolbar = navigationController?.toolbar
    switch state
    {
    case .Disabled: toolbar?.setItems(inactiveToolbarItems, animated: true)
    default:        toolbar?.setItems(  activeToolbarItems, animated: true)
    }
    
    currentView.applyState(state)
  }
  
  func handleLocationUpdate()
  {
    switch dataController.state
    {
    case .Inserting: fallthrough
    case .Editing:
      recordBarItem.isEnabled = dataController.okToRecord
    default:
      break;
    }
  }
  
  func handleOn(_ sender: UIBarButtonItem)
  {
    dataController.updateState(.Enabled(true))
  }
  
  func handleOff(_ sender: UIBarButtonItem)
  {
    dataController.updateState(.Enabled(false))
  }
  
  func handleStart(_ sender: UIBarButtonItem)
  {
    let doStart = { self.dataController.updateState(.Insert(nil)) }

    if dataController.locked
    {
      let alert = UIAlertController(title: "Unlock Route",
                                    message: "Please confirm updating the route (you will not be able to undo changes)",
                                    preferredStyle: .alert)
      
      alert.addAction( UIAlertAction(title: "OK", style: .destructive) { (_:UIAlertAction) in doStart() } )
      alert.addAction( UIAlertAction(title: "Cancel", style: .cancel) )
      
      self.present(alert, animated: true)
    }
    else
    {
      doStart()
    }
  }
  
  func handlePause(_ sender: UIBarButtonItem)
  {
    dataController.updateState(.Cancel)
  }
  
  func handleRecord(_ sender: UIBarButtonItem)
  {
    dataController.record()
    lastRecordTime = Date()
  }
  
  func handleUndo(_ sender: UIBarButtonItem)
  {
    dataController.undoRecord()
  }
  
  func handleShare(_ sender: UIBarButtonItem)
  {
    print("DVC handleShare")
  }
}
