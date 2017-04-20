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
  func trackingView(_ tv: TrackingView, modeDidChange mode: MKUserTrackingMode)
}

class TrackingView: UIView
{
  @IBOutlet weak var button   : UIButton!
  @IBOutlet weak var delegate : TrackingViewDelegate?
  
  private var cachedMode : MKUserTrackingMode?
  
  var mode = MKUserTrackingMode.none
  {
    didSet
    {
      if mode != oldValue
      {
        delegate?.trackingView(self, modeDidChange: mode)
        
        var newImage : UIImage?
        switch mode
        {
        case .none:              newImage = UIImage(named: "TrackOff_000000_25")
        case .follow:            newImage = UIImage(named: "TrackOn_000000_25")
        case .followWithHeading: newImage = UIImage(named: "TrackHeading_000000_25")
        }
        
        button.setImage(newImage, for: .normal)
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
    case .none:              self.mode = .follow
    case .follow:            self.mode = .followWithHeading
    case .followWithHeading: self.mode = .none
    }
  }
}
