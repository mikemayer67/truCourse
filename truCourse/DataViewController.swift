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
  private var pausedToolbarItems   : [UIBarButtonItem]!
  private var inactiveToolbarItems : [UIBarButtonItem]!
  private var onBarItem            : UIBarButtonItem!
  private var offBarItem           : UIBarButtonItem!
  private var startBarItem         : UIBarButtonItem!
  private var stopBarItem          : UIBarButtonItem!
  private var recordBarItem        : UIBarButtonItem!
  private var undoBarItem          : UIBarButtonItem!
  private var redoBarItem          : UIBarButtonItem!
  private var shareBarItem         : UIBarButtonItem!
  private var saveBarItem          : UIBarButtonItem!
  
  private var lastRecordTime       : Date?
      
  private(set) var route : Route?
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
        
    let sb = self.storyboard!
    
    let mapViewController     = sb.instantiateViewController(withIdentifier: "mapViewController")     as! MapViewController
    let bearingViewController = sb.instantiateViewController(withIdentifier: "bearingViewController") as! BearingViewController
    let latLonViewController  = sb.instantiateViewController(withIdentifier: "latLonViewController")  as! LatLonViewController
    
    
    visualizationControllers = [ .MapView     : mapViewController,
                                 .BearingView : bearingViewController,
                                 .LatLonView  : latLonViewController ]
    
    mapViewController.dataController     = dataController
    bearingViewController.dataController = dataController
    latLonViewController.dataController  = dataController
    
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
    redoBarItem   = UIBarButtonItem(image: UIImage(named:"Redo_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleRedo(_:)))
    shareBarItem  = UIBarButtonItem(image: UIImage(named:"Upload_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleShare(_:)))
    saveBarItem   = UIBarButtonItem(image: UIImage(named:"Save_file_ffffff_25.png"),
                                    style: .plain, target: self, action: #selector(handleSave(_:)))
    
    let onOffTint = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
    onBarItem.tintColor  = onOffTint
    offBarItem.tintColor = onOffTint
    
    startBarItem.tintColor  = UIColor.white
    stopBarItem.tintColor   = UIColor.white
    recordBarItem.tintColor = UIColor.white
    undoBarItem.tintColor   = UIColor.white
    redoBarItem.tintColor   = UIColor.white
    shareBarItem.tintColor  = UIColor.white
    saveBarItem.tintColor   = UIColor.white
    
    activeToolbarItems = [
      /*0*/ offBarItem,
      /*1*/ stopBarItem,
      /*2*/ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      /*3*/ recordBarItem,
      /*4*/ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      /*5*/ shareBarItem,
      /*6*/ saveBarItem
    ]
    
    pausedToolbarItems = [
      /*0*/ onBarItem,
      /*1*/ startBarItem,
      /*2*/ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      /*3*/ undoBarItem,
      /*4*/ redoBarItem,
      /*5*/ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      /*6*/ shareBarItem,
      /*7*/ saveBarItem
    ]
    
    let disabledBarItem = UIBarButtonItem(title: "location services diabled", style: .plain, target: nil, action: nil)
    
    disabledBarItem.tintColor = UIColor.yellow

    inactiveToolbarItems = [
      disabledBarItem,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      shareBarItem,
      saveBarItem
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
    case .Disabled:       toolbar?.setItems(inactiveToolbarItems, animated: true)
    case .Paused, .Idle:  toolbar?.setItems(pausedToolbarItems,   animated: true)
    default:              toolbar?.setItems(  activeToolbarItems, animated: true)
    }
  }

  override func applyOptions()
  {
    for (_,controller) in visualizationControllers { controller.applyOptions() }
  }
  
  // MARK: - Passtroughs to View Controller
  
  func updateRoute(route:Route)
  {
    currentView.update(route:route)
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
    let options = Options.shared
    
    switch motion
    {
    case .motionShake:
      if options.canShakeUndo
      {
        if lastRecordTime != nil && options.shakeUndoTimeout != nil
        {
          if Date().timeIntervalSince(lastRecordTime!) <= options.shakeUndoTimeout!
          {
            lastRecordTime = nil
            UndoManager.shared.undo()
          }
        }
      }
    default:
      break
    }
  }
  
  // MARK: - OptionViewController Delegate
  
  func optionViewController(updatedOptions: Options)
  {
    Options.shared = updatedOptions
    
    applyOptions()
    dataController.updateOptions()
  }
  
  // MARK: - Toolbar handler
  
  func applyState()
  {
    let state = dataController.state
    
    shareBarItem.isEnabled = dataController.canShare
    saveBarItem.isEnabled  = dataController.canSave
    
    let toolbar = navigationController?.toolbar
    
    switch state
    {
    case .Uninitialized: break
    case .Disabled:
      toolbar?.setItems(inactiveToolbarItems, animated: true)
      
    case .Paused:
      pausedToolbarItems[0]  = onBarItem
      startBarItem.isEnabled = false
      undoBarItem.isEnabled  = UndoManager.shared.hasUndo
      redoBarItem.isEnabled  = UndoManager.shared.hasRedo
      toolbar?.setItems(pausedToolbarItems, animated: true)
      
    case .Idle:
      pausedToolbarItems[0]  = offBarItem
      startBarItem.isEnabled = true
      undoBarItem.isEnabled  = UndoManager.shared.hasUndo
      redoBarItem.isEnabled  = UndoManager.shared.hasRedo
      toolbar?.setItems(pausedToolbarItems, animated: true)
      
    case .Inserting, .Editing:
      recordBarItem.isEnabled = dataController.okToRecord
      toolbar?.setItems(activeToolbarItems, animated: true)

    }
    
    currentView.applyState(state)
  }
  
  func handleLocationUpdate()
  {
    switch dataController.state
    {
    case .Inserting, .Editing:
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
    self.confirmAction(type: .Insertion,
                       action: { self.dataController.updateState(.Insert(nil)) } )
  }
  
  func handlePause(_ sender: UIBarButtonItem)
  {
    dataController.updateState(.Pause)
  }
  
  func handleRecord(_ sender: UIBarButtonItem)
  {
    dataController.record()
    lastRecordTime = Date()
  }
  
  func handleUndo(_ sender: UIBarButtonItem)
  {
    UndoManager.shared.undo()
  }
  
  func handleRedo(_ sender: UIBarButtonItem)
  {
    UndoManager.shared.redo()
  }
  
  func handleShare(_ sender: UIBarButtonItem)
  {
    print("DVC handleShare")
  }
  
  func handleSave(_ sender: UIBarButtonItem)
  {
    print("DVC handleSave")
  }
  
  // MARK: - Confirmation Dialog
  
  func confirmAction(type:ActionType, action:@escaping ()->Void, failure:@escaping ()->Void)
  {
    var confirmationRequired = true
    var title   : String?
    var message : String?
    
    switch type
    {
    case .Insertion:
      
      if dataController.locked
      {
        title = "Unlock route"
        message = "Please confirm updating the saved route"
      }
      else
      {
        confirmationRequired = false
      }
      
    case .Deletion(let post):
      
      if dataController.locked
      {
        title = "Unlock and Delete Post \(post)"
        message = "Please confirm deleting post \(post) from the saved route.  (This will unlock the route for future modifications)"
      }
      else
      {
        title = "Delete Post \(post)"
        message = "Please confirm deleting post \(post)"
      }
    }
    
    if confirmationRequired
    {
      let alert = UIAlertController(title:title, message:message, preferredStyle: .alert)
      
      alert.addAction( UIAlertAction(title: "OK",    style: .destructive) { (_:UIAlertAction) in action() } )
      alert.addAction( UIAlertAction(title: "Cancel", style: .cancel)     { (_:UIAlertAction) in failure() } )
      
      self.present(alert, animated: true)
    }
    else
    {
      action()
    }
  }
  
  func confirmAction(type:ActionType, action: @escaping ()->Void)
  {
    confirmAction(type:type, action:action, failure:{})
  }
}
