//
//  TrackingBackView.swift
//  truCourse
//
//  Created by Mike Mayer on 4/20/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

class TrackingView: UIView, UIGestureRecognizerDelegate
{
  @IBOutlet weak var button   : UIButton!
  
  weak var mapViewController  : MapViewController!
  
  private var timer : Timer?
  
  private var _mode         = MKUserTrackingMode.none
  private var autoScaling = false
  
  private var cachedMode : (MKUserTrackingMode,Bool)?
  
  func updateIcon()
  {
    var icon : UIImage?
    switch (_mode,autoScaling)
    {
    case (.none,false):          icon = UIImage(named: "TrackOff_000000_25")
    case (.none,true):           icon = UIImage(named: "TrackPosts_000000_25")
    case (.follow,_):            icon = UIImage(named: "TrackOn_000000_25")
    case (.followWithHeading,_): icon = UIImage(named: "TrackHeading_000000_25")
    default:
      fatalError("compiler claimed this list wasn't exhaustive.  guess it was right")
    }
    button.setImage(icon, for: .normal)
  }
  
  var paused : Bool = false
  {
    didSet
    {
      if paused != oldValue
      {
        if paused
        {
          cachedMode = (_mode,autoScaling)
          _mode = .none
          pauseAutoScaling()
        }
        else
        {
          if let (m,a) = cachedMode
          {
            _mode = m
            autoScaling = a
            cachedMode = nil
            
            if autoScaling { resumeAutoScaling() }
          }
        }
      }
    }
  }
  
  override func draw(_ rect: CGRect)
  {
    let context = UIGraphicsGetCurrentContext()
    
    let fg = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7).cgColor
    let bg = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.5).cgColor
    context?.setFillColor(fg)
    context?.fillEllipse(in: rect)
    context?.setStrokeColor(bg)
    context?.strokeEllipse(in: rect)
  }
  
  // MARK: - Handle mode changes
  
  func initTrackingMode(_ mode:MKUserTrackingMode, autoScaling : Bool = false)
  {
    _mode = mode
    
    if mapViewController.mapView.userTrackingMode != _mode
    {
      mapViewController.mapView.setUserTrackingMode(_mode, animated: true)
    }
    
    // Note for attempting to initialize the mode to enable auto tracking.
    //   (mode = .none and autoScaling = true)
    // If the initial tracking mode of the map view is something other than none,
    //   - setUserTrackingMode will be called above to set the mode to .none.
    //   - change will trigger a modeDidChange notification
    //   - if that is handled AFTER the following statement, then it will disable auto tracking
    
    self.autoScaling = autoScaling
  }
  
  // User tapped the tracking view "button"
  @IBAction func updateTrackingMode(_ sender: UIButton)
  {
    switch (_mode,autoScaling)
    {
    case (.none,false):
      autoScaling = true
    case (.none,true):
      autoScaling = false
      if paused == false { _mode = .follow }
    case (.follow,_):
      _mode = .followWithHeading
      autoScaling = false
    case (.followWithHeading,_):
      _mode = .none
      autoScaling = false
    default:
      fatalError("compiler claimed list wasn't exhaustive... guess it was right")
    }
    
    if autoScaling { resumeAutoScaling() }
    else           { pauseAutoScaling()  }
    
    updateIcon()
    
    if mapViewController.mapView.userTrackingMode != _mode
    {
      mapViewController.mapView.setUserTrackingMode(_mode, animated: true)
    }
  }
  
  // MapView sent a didUpdateTrackingMode notification to map view controller
  func userTrackingModeChanged(to mode:MKUserTrackingMode)
  {
    self._mode = mode
    if mode == .none { autoScaling = false }
    
    updateIcon()
  }
  
  // MARK: - Show All Posts

  func routeDidChange()
  {
    if _mode == .none && autoScaling { showAllPosts() }
  }
  
  func showAllPosts()
  {
    mapViewController.showAllPosts()
  }
  
  // MARK: - Auto scaling
  
  func resumeAutoScaling()
  {
    if _mode == .none && autoScaling
    {
      showAllPosts()
      
      // only start timer if allowed by options (and not already running)
      
      guard Options.shared.autoScale  else { return }  // auto-scaling not currently enabled
      guard timer == nil              else { return }  // auto-scaling already running
      
      timer = Timer.scheduledTimer(timeInterval: 3.0,
                                   target: self,
                                   selector: #selector(showAllPosts),
                                   userInfo: nil,
                                   repeats: true)
    }
  }
  
  func pauseAutoScaling()
  {
    timer?.invalidate()
    timer = nil
  }
  
  
  // MARK: - User gestures in Map
  
  func gestureRecognizer(_ sender: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
  {
    return true
  }
  
  func userDraggedMap(_ gr:UIGestureRecognizer)
  {
    if _mode == .none && autoScaling
    {
      autoScaling = false
      pauseAutoScaling()
      updateIcon()
    }
  }
  
  func userTappedMap(_ sender: UITapGestureRecognizer)
  {
    if _mode == .none && autoScaling
    {
      autoScaling = false
      pauseAutoScaling()
      updateIcon()
    }
  }
}
