//
//  RouteDetailViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 5/8/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import CoreLocation

class RouteDetailViewController: UIViewController
{
  @IBOutlet weak var modalView: UIView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var createdLabel: UILabel!
  @IBOutlet weak var updatedLabel: UILabel!
  @IBOutlet weak var lengthLabel: UILabel!
  @IBOutlet weak var postsLabel: UILabel!
  @IBOutlet weak var declinationLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var proximityLabel: UILabel!
  @IBOutlet weak var descriptionText: UITextView!
  
  weak var route: Route!
  weak var here:  CLLocation?
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    let options = Options.shared
    
    modalView.layer.borderColor = UIColor.black.cgColor
    modalView.layer.borderWidth = 1.0
    modalView.layer.cornerRadius = 10.0
    modalView.layer.shadowOffset = CGSize(width: 5, height: 5)
    
    descriptionText.layer.borderColor = UIColor.gray.cgColor
    descriptionText.layer.borderWidth = 1.0
    
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .short
    let dateCreated = formatter.string(from: route.created)
    let dateUpdated = formatter.string(from: route.lastSaved!)
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    let timeCreated = formatter.string(from: route.created)
    let timeUpdated = formatter.string(from: route.lastSaved!)
    
    nameLabel.text = route.name
    
    createdLabel.text = "\(dateCreated), \(timeCreated)"
    updatedLabel.text = "\(dateUpdated), \(timeUpdated)"
    
    latitudeLabel.text = route.firstPostLocation?.latitudeString
    longitudeLabel.text = route.firstPostLocation?.longitudeString
    
    if here == nil
    {
      proximityLabel.text = nil
    }
    else
    {
      proximityLabel.text = options.distanceString(route.proximity(to: here!)).appending(" from here")
    }
    
    if let length = route.distance
    {
      lengthLabel.text = options.distanceString(length)
    }
    else
    {
      lengthLabel.text = "unknown"
    }
    
    postsLabel.text = "\(route.count)"
    
    if let decl = route.declination
    {
      declinationLabel.text = "\(decl)"
    }
    else
    {
      declinationLabel.text = "unknown"
    }
    
    descriptionText.text = route.description
  }
  
  
  @IBAction func handleDismiss(_ sender: UITapGestureRecognizer)
  {
    self.dismiss(animated: true)
  }
  
  
}
