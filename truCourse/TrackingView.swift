//
//  TrackingBackView.swift
//  truCourse
//
//  Created by Mike Mayer on 4/20/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

@objc protocol TrackingViewDelegate
{
  func trackingView(_ tv: TrackingView, modeDidChange mode: Int)
}

class TrackingView: UIView
{
  @IBOutlet weak var button   : UIButton!
  @IBOutlet weak var delegate : TrackingViewDelegate?
  
  enum Mode : Int
  {
    case trackOff
    case trackPosts
    case trackFollow
    case trackHeading
  }
  
  private var cachedMode : Mode?
  
  var mode = Mode.trackOff
  {
    didSet
    {
      if mode != oldValue
      {
        print("Tracking mode updated from \(oldValue) to \(mode)")
        delegate?.trackingView(self, modeDidChange: mode.rawValue)
        
        var newImage : UIImage?
        switch mode
        {
        case .trackOff:      newImage = UIImage(named: "TrackOff_000000_25")
        case .trackPosts:    newImage = UIImage(named: "TrackPosts_000000_25")
        case .trackFollow:   newImage = UIImage(named: "TrackOn_000000_25")
        case .trackHeading:  newImage = UIImage(named: "TrackHeading_000000_25")
        }
        
        button.setImage(newImage, for: .normal)
      }
    }
  }
  
  var mkTrackingMode : MKUserTrackingMode
    {
    get {
      switch self.mode
      {
      case .trackOff:      return .none
      case .trackPosts:    return .none
      case .trackFollow:   return .follow
      case .trackHeading:  return .followWithHeading
      }
    }
  }
  
  func pause()
  {
    if button.isEnabled
    {
      button.isEnabled = false
      cachedMode = mode
    }
  }
  
  func resume()
  {
    if button.isEnabled == false
    {
      button.isEnabled = true
      if cachedMode != nil
      {
        mode = cachedMode!;
        cachedMode = nil
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
  
  @IBAction func updateTrackingMode(_ sender: UIButton)
  {
    switch self.mode
    {
    case .trackOff:       self.mode = .trackPosts
    case .trackPosts:     self.mode = .trackFollow
    case .trackFollow:    self.mode = .trackHeading
    case .trackHeading:   self.mode = .trackOff
    }
  }
}
