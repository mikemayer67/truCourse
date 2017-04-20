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
  
  private(set) var trackingOption  = MKUserTrackingMode.none
  private(set) var trackingEnabled = false
  
  private var routeOverlay    : MKOverlay?
  private var candOverlay     : MKOverlay?
  private var postAnnotations = [Int:PostAnnotation]()
  private var postNorth       : NorthType = .True
  private var postUnits       : BaseUnitType = .English
  
  private var candPrevWaypoint : Waypoint?
  
   var _visualizationType : VisualizationType { return .MapView }
   var _hasSelection      : Bool              { return false    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    mapView.mapType           = .standard
    mapView.userTrackingMode  = .follow
    mapView.showsUserLocation = true
    mapView.showsScale        = true
  }
  
  // MARK: - Options
  
  func _applyOptions()
  {
    let options = Options.shared
    
    mapView.mapType    = options.mapType
    mapView.showsScale = options.showScale
    
    for (_,post) in postAnnotations { post.applyOptions() }
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
  }
  
  // MARK: - Map View delegate methods
  
  func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
  {
    print("New tracking mode: \(mode.rawValue)")
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
  {
    var rval : MKAnnotationView?
    
    if let pa = annotation as? PostAnnotation
    {
      var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "PostAnnotationView")
      if pin == nil
      {
        pin = MKAnnotationView(annotation: pa, reuseIdentifier: "PostAnnotationView")
        pin?.canShowCallout = true
      }
      pin?.image        = pa.image
      pin?.centerOffset = pa.centerOffset
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
          post.waypoint = wp
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
    
    mapView.userLocation.title = "(me)"
    mapView.userLocation.subtitle = nil
    
    guard let cand = candidate else
    {
      if candPrevWaypoint != nil
      {
        postAnnotations[candPrevWaypoint!.index!]?.updateTitle()
        candPrevWaypoint = nil
      }
      return
    }

    mapView.userLocation.title    = cand.annotationTitle ?? "(me)"
    mapView.userLocation.subtitle = cand.annotationSubtitle
    
    guard let prev = cand.prev else { return }
    guard let next = cand.next else { return }
    
    var coords = [ prev.location, cand.location, next.location ]
    
    candOverlay = MKPolyline(coordinates:&coords, count:3)
    self.mapView.add(candOverlay!)
    
    postAnnotations[prev.index!]?.updateTitle()
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
