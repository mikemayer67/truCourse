//
//  DataPageController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreLocation

class DataPageController :
  UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate,
  OptionViewControllerDelegate, UndoManagerObserver
{
  @IBOutlet var viewTypeControl : UISegmentedControl!
  
  private var activeToolbar         = true
  private var activeToolbarItems    : [UIBarButtonItem]!
  private var pausedToolbarItems    : [UIBarButtonItem]!
  private var inactiveToolbarItems  : [UIBarButtonItem]!
  private var onBarItem             : UIBarButtonItem!
  private var offBarItem            : UIBarButtonItem!
  private var startBarItem          : UIBarButtonItem!
  private var stopBarItem           : UIBarButtonItem!
  private var recordBarItem         : UIBarButtonItem!
  private var undoBarItem           : UIBarButtonItem!
  private var redoBarItem           : UIBarButtonItem!
  private var shareBarItem          : UIBarButtonItem!
  private var saveBarItem           : UIBarButtonItem!
  
  private var mapVC                 : MapViewController!
  private var bearingVC             : ListViewController!
  private var latlonVC              : ListViewController!
  
  private var allDataVC             : [DataViewController]!
  
  private var dataVC                : DataViewController!
  {
    didSet
    {
      if dataVC !== oldValue { dataVC.updateRoute(DataController.shared.route) }
    }
  }
  
  private var uiVC                  : UIViewController
  {
    get { return dataVC as! UIViewController }
    set { dataVC = newValue as! DataViewController }
  }
  
  private var lastRecordTime       : Date?
      
  private(set) var route : Route?
  
  // MARK: - View methods
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    DataController.shared.dataPageController = self
    
    let sb = self.storyboard!
    
    mapVC     = sb.instantiateViewController(withIdentifier: "mapViewController")  as! MapViewController
    bearingVC = sb.instantiateViewController(withIdentifier: "listViewController") as! ListViewController
    latlonVC  = sb.instantiateViewController(withIdentifier: "listViewController") as! ListViewController
    
    let latlonView = latlonVC.tableView as! ListView
    latlonView.separatorColor = UIColor.red
    latlonView.dataSource = DataController.shared
    latlonView.type = .latlon
    
    let bearingView = bearingVC.tableView as! ListView
    bearingView.dataSource = DataController.shared
    bearingView.type = .bearing
    
    allDataVC = [ mapVC, bearingVC, latlonVC ]
    
    for i in 0...(allDataVC.count-1)
    {
      let dvc = allDataVC[i]
      (dvc as! UIViewController).view.tag = i
    }
        
    dataVC = mapVC
    
    self.navigationController!.navigationBar.tintColor = UIColor.white
    (self.navigationController as! MainController).dataPageController = self
    
    self.dataSource = self
    self.delegate = self
    self.setViewControllers([uiVC], direction: .forward, animated: false, completion: nil)
    
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
    
    UndoManager.shared.add(observer: self)
    updateUndoState(using:UndoManager.shared)
    
    applyOptions()
    
    DataController.shared.updateState(.Start)
  }
  
  func updateUndoState(using um: UndoManager)
  {
    undoBarItem.isEnabled  = um.hasUndo
    redoBarItem.isEnabled  = um.hasRedo
  }
  
  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    
    let toolbar = navigationController?.toolbar
    switch DataController.shared.state
    {
    case .Disabled:       toolbar?.setItems(inactiveToolbarItems, animated: true)
    case .Paused, .Idle:  toolbar?.setItems(pausedToolbarItems,   animated: true)
    default:              toolbar?.setItems(  activeToolbarItems, animated: true)
    }
  }

  func applyOptions()
  {
    allDataVC.forEach { $0.applyOptions() }
  }
  
  // MARK: - Passtroughs to View Controller
  
  func updateRoute(_ route:Route)
  {
    dataVC.updateRoute(route)
    self.applyState()
  }
  
  func updateCandidate(_ candidate:Waypoint)
  {
    dataVC.updateCandidate(candidate)
  }
  
  func removeCandidate()
  {
    dataVC.updateCandidate(nil)
  }

  // MARK: - Page View Data Source
  
  @IBAction func setCurrentViewType(_ sender: UISegmentedControl)
  {
    let curIndex = uiVC.view.tag
    let newIndex = sender.selectedSegmentIndex
    
    let newVC = allDataVC[newIndex]
    
    if( newVC !== dataVC)
    {
      let delta = newIndex - curIndex

      dataVC = newVC

      self.setViewControllers( [uiVC],
                              direction: ( (delta == 1)||(delta == -2) ? .forward : .reverse),
                              animated: true)
      
    }
  }
  
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter vc: UIViewController ) -> UIViewController?
  {
    let n = allDataVC.count
    return allDataVC[ (vc.view.tag + 1) % n ] as? UIViewController
  }
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore vc: UIViewController ) -> UIViewController?
  {
    let n = allDataVC.count
    return allDataVC[ (vc.view.tag + n-1) % n ] as? UIViewController
  }
  
  // MARK: - Page View Delegate
  
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool)
  {
    if finished && completed
    {
      uiVC = viewControllers![0]
      viewTypeControl.selectedSegmentIndex = uiVC.view.tag
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
    DataController.shared.updateOptions()
  }
  
  // MARK: - Toolbar handler
  
  func applyState()
  {
    let state = DataController.shared.state
    
    shareBarItem.isEnabled = DataController.shared.canShare
    saveBarItem.isEnabled  = DataController.shared.canSave
    
    let toolbar = navigationController?.toolbar
    
    switch state
    {
    case .Uninitialized: break
    case .Disabled:
      toolbar?.setItems(inactiveToolbarItems, animated: true)
      
    case .Paused:
      pausedToolbarItems[0]  = onBarItem
      startBarItem.isEnabled = false
      toolbar?.setItems(pausedToolbarItems, animated: true)
      
    case .Idle:
      pausedToolbarItems[0]  = offBarItem
      startBarItem.isEnabled = true
      toolbar?.setItems(pausedToolbarItems, animated: true)
      
    case .Inserting:
      recordBarItem.isEnabled = DataController.shared.okToRecord
      toolbar?.setItems(activeToolbarItems, animated: true)

    }
    
    dataVC.applyState(state)
  }
  
  func handleLocationUpdate()
  {
    switch DataController.shared.state
    {
    case .Inserting:
      recordBarItem.isEnabled = DataController.shared.okToRecord
    default:
      break;
    }
  }
  
  func handleOn(_ sender: UIBarButtonItem)
  {
    DataController.shared.updateState(.Enabled(true))
  }
  
  func handleOff(_ sender: UIBarButtonItem)
  {
    DataController.shared.updateState(.Enabled(false))
  }
  
  func handleStart(_ sender: UIBarButtonItem)
  {
    self.confirmAction(type: .Insertion,
                       action: { DataController.shared.updateState(.Insert(nil)) } )
  }
  
  func handlePause(_ sender: UIBarButtonItem)
  {
    DataController.shared.updateState(.Pause)
  }
  
  func handleRecord(_ sender: UIBarButtonItem)
  {
    DataController.shared.record()
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
    DataController.shared.shareRoute()
  }
  
  func handleSave(_ sender: UIBarButtonItem)
  {
    DataController.shared.saveRoute()
  }
  
  // MARK: - Confirmation Dialog
  
  func confirmAction(type:ActionType, action:@escaping ()->Void, failure:@escaping ()->Void)
  {
    var confirmationRequired = true
    var title   : String?
    var message : String?
    
    switch type
    {
    case .Deletion(let post):
      
      if DataController.shared.locked
      {
        title = "Unlock and Delete Post \(post)"
        message = "Please confirm deleting post \(post) from the saved route.  (This will unlock the route for future modifications)"
      }
      else
      {
        title = "Delete Post \(post)"
        message = "Please confirm deleting post \(post)"
      }
      
    case .NewWorkingRoute(let oldRoute, let newRoute):
      
      if oldRoute.dirty
      {
        title = "Discard Unsaved Route"
        
        let oldName = ( oldRoute.name == nil ? "working route" : oldRoute.name!)
        let newName = ( newRoute == nil      ? "new route"     : newRoute!.name!)
        
        message = "Loading \(newName) will result in unsaved changes to \(oldName)"
      }
      else
      {
        confirmationRequired = false
      }
      
    default:
      
      if DataController.shared.locked
      {
        title = "Unlock route"
        message = "Please confirm updating the saved route"
      }
      else
      {
        confirmationRequired = false
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
