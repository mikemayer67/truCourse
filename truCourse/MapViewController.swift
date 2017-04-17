//
//  MapViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, VisualizationView, MKMapViewDelegate
{
  @IBOutlet weak var mapView        : MKMapView!
  @IBOutlet weak var recenterButton : UIButton!
  
  private(set) var trackingOption  = MKUserTrackingMode.none
  private(set) var trackingEnabled = false
  
  private      var recenterButtonEnabled = true
  
  private var routeOverlay    : MKOverlay?
  private var candOverlay     : MKOverlay?
  private var postAnnotations = [Int:PostAnnotation]()
  private var postNorth       : NorthType = .True
  private var postUnits       : BaseUnitType = .English
  
  private var candPrevWaypoint : Waypoint?
  
  var trackingMode : MKUserTrackingMode
  {
    return trackingEnabled ? trackingOption : .none
  }
  
   var _visualizationType : VisualizationType { return .MapView }
   var _hasSelection      : Bool              { return false    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    mapView.mapType           = .standard
    mapView.userTrackingMode  = .none
    mapView.showsUserLocation = false
    mapView.showsScale        = true
  }
  
  // MARK: - Options
  
  func _applyOptions(_ options: Options)
  {
    print("applyOptions")
    mapView.mapType = options.mapType
    trackingOption  = options.trackingMode
    
    mapView.showsScale = options.showScale
    
    handleRecenter(nil)
    
    for (_,post) in postAnnotations { post.applyOptions(options) }
  }
  
  // MARK: - State
  
  func _applyState(_ state: AppState)
  {
    switch state
    {
    case .Uninitialized: fallthrough
    case .Disabled:      fallthrough
    case .Paused:
      trackingEnabled = false
    default:
      trackingEnabled = true
    }
    
    recenterButtonEnabled = false
    handleRecenter(nil)
    recenterButtonEnabled = true
  }
  
  // MARK: - Recenter
  
  @IBAction func handleRecenter(_ sender: UIButton?)
  {
    let newTrackingMode = self.trackingMode
    
    mapView.showsUserLocation = (newTrackingMode != .none)
    mapView.setUserTrackingMode(newTrackingMode, animated: true)
    
    recenterButton.isEnabled = false

    UIView.animate(withDuration: 0.35,
                   animations: { self.recenterButton.alpha = 0.0 })
    {
      (finished:Bool) in
      self.recenterButton.isHidden = true
    }
  }
  
  // MARK: - Map View delegate methods
  
  func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
  {
    print("New tracking mode: \(mode.rawValue)")

    guard recenterButtonEnabled else { return }
    
    recenterButton.alpha = 0.0
    recenterButton.isHidden = false
    UIView.animate(withDuration: 0.35,
                   animations: { self.recenterButton.alpha = 1.0 })
    {
      (finished:Bool) in
      self.recenterButton.isEnabled = true
    }
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
  {
    var rval : MKAnnotationView?
    
    if annotation is PostAnnotation
    {
      var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "PostAnnotationView") as! MKPinAnnotationView?
      if pin == nil
      {
        pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PostAnnotationView")
        pin?.canShowCallout = true
        pin?.pinTintColor = MKPinAnnotationView.redPinColor()
        pin?.animatesDrop = true
      }
      rval = pin
    }
    
    return rval
  }
  
  // MARK: - Route update
  
  func _updateRoute(_ route: Route)
  {
    let head = route.head
    var cand : Waypoint?
    
    var coords = [CLLocationCoordinate2D]()
    
    var existingPosts = postAnnotations
    postAnnotations.removeAll()
    
    head?.iterate(
      { (wp:Waypoint) in
        coords.append(wp.location)
        if wp.cand != nil { cand = wp.cand }
        
        if let post = existingPosts.removeValue(forKey: wp.index!)
        {
          post.update(wp)
          postAnnotations[wp.index!] = post
        }
        else
        {
          let post = PostAnnotation(wp, north:postNorth, units:postUnits)
          mapView.addAnnotation( post )
          postAnnotations[wp.index!] = post
        }
      }
    )
    
    for (_,post) in existingPosts
    {
      mapView.removeAnnotation(post)
    }
    
    if routeOverlay != nil { self.mapView.remove(routeOverlay!) }
    
    if coords.count > 1
    {
      if coords.count > 2 { coords.append(coords[0]) }
      routeOverlay = MKPolyline(coordinates:&coords, count: coords.count)
      self.mapView.add(routeOverlay!)
    }
    else
    {
      routeOverlay = nil
    }
    
    if cand != nil { _updateCandidate(cand!) }
  }
  
  func _updateCandidate(_ candidate: Waypoint?)
  {
    if candOverlay != nil
    {
      self.mapView.remove(candOverlay!)
      candOverlay = nil
    }
    
    guard let cand = candidate else
    {
      if candPrevWaypoint != nil
      {
        postAnnotations[candPrevWaypoint!.index!]?.update(candPrevWaypoint!)
        candPrevWaypoint = nil
      }
      return
    }
    
    guard let prev = cand.prev else { return }
    guard let next = cand.next else { return }
    
    var coords = [ prev.location, cand.location, next.location ]
    
    candOverlay = MKPolyline(coordinates:&coords, count:3)
    self.mapView.add(candOverlay!)
    
    postAnnotations[prev.index!]?.update(prev)
    candPrevWaypoint = prev
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
  {
    if routeOverlay === overlay
    {
      let path = MKPolylineRenderer(overlay: overlay)
      path.strokeColor = UIColor.purple
      path.lineWidth = 2.0
      return path
    }
    else if candOverlay === overlay
    {
      let path = MKPolylineRenderer(overlay: overlay)
      path.strokeColor = UIColor.purple
      path.lineWidth = 1.0
      path.lineDashPattern = [4,4]
      return path
    }
    else
    {
      fatalError("request for renderer for unknown overlay")
    }
  }
}
