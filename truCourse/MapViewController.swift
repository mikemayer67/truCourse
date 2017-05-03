//
//  MapViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, VisualizationView, MKMapViewDelegate, TrackingViewDelegate
{
  @IBOutlet weak var mapView        : MKMapView!
  @IBOutlet weak var trackingView   : TrackingView!
  
  weak var dataController : DataController?
  
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
    
    trackingView.delegate = self
    trackingView.mode = .trackFollow
    
    mapView.mapType           = .standard
    mapView.showsUserLocation = true
    mapView.setUserTrackingMode(trackingView.mkTrackingMode, animated: true)
    mapView.showsScale        = true
    
    mapView.remove { (gr:UIGestureRecognizer)->Bool in return gr is UILongPressGestureRecognizer }
  }

  // MARK: - Options
  
  func _applyOptions()
  {
    let options = Options.shared
    
    mapView.mapType    = options.mapType
    mapView.showsScale = options.showScale
    
    for (_,post) in postAnnotations { post.updateTitle() }
  }
  
  // MARK: - State
  
  func _applyState(_ state: AppState)
  {
    switch state
    {
    case .Uninitialized, .Disabled, .Paused:
      trackingView.pause()
      mapView.showsUserLocation = false
      mapView.setUserTrackingMode(.none, animated: false)
    default:
      trackingView.resume()
      mapView.showsUserLocation = true
      mapView.setUserTrackingMode(trackingView.mkTrackingMode, animated: true)
    }
  }
  
  func trackingView(_ tv: TrackingView, modeDidChange newMode: Int)
  {
    mapView.setUserTrackingMode(tv.mkTrackingMode, animated: true)
   
    if tv.mode == .trackPosts { self.viewPosts() }
  }
  
  // MARK: - Map View delegate methods
  
  func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
  {
    print("mapView: newMode:\(mode.rawValue) oldMode:\(trackingView.mode)")
    switch(mode)
    {
    case .none:              trackingView.mode = .trackOff
    case .follow:            trackingView.mode = .trackFollow
    case .followWithHeading: trackingView.mode = .trackHeading
    }
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
      
      let popup = UILongPressGestureRecognizer(target: self, action: #selector(handlePopup(_:)))
      pin?.addGestureRecognizer(popup)
    }
    
    return rval
  }
  
  func handlePopup(_ sender:UILongPressGestureRecognizer)
  {
    guard dataController != nil  else { return }
    guard sender.state == .began else { return }
    
    sender.isEnabled = false  // cancels the long press gesture now that it's recognized
    sender.isEnabled = true   // rather than waiting for user to let go of screen
    
    let postView = sender.view as! MKAnnotationView
    let post     = postView.annotation as! PostAnnotation
    let index    = post.waypoint.index!
    
    let actions = dataController!.popupActions(for: index)
    
    if actions == nil { return }
    
    let alert = UIAlertController( title: "Post \(index) selected",
                                   message: "What do you want to do?",
                                   preferredStyle: .actionSheet)
    
    actions!.forEach { alert.addAction($0) }
  
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    self.present(alert, animated:true)
  }
  
  // MARK: - Route update
  
  func _updateRoute(_ route: Route)
  {
    let head = route.head
    var cand : Waypoint?
    
    var coords = [CLLocationCoordinate2D]()
    
    var existingPosts = postAnnotations
    postAnnotations.removeAll()
    
    var waypoints = [Waypoint]()
    
    head?.iterate(
      { (wp:Waypoint) in
        coords.append(wp.location)
        
        waypoints.append(wp)
        
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
    
    if trackingView.mode == .trackPosts { self.viewPosts() }
    
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
    
    if candPrevWaypoint != nil && cand.prev !== candPrevWaypoint
    {
      postAnnotations[candPrevWaypoint!.index!]?.updateTitle()
      candPrevWaypoint = nil
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
  
  func viewPosts()
  {
    var annotations = [MKAnnotation]()
    postAnnotations.forEach { (_,value) in annotations.append(value) }
    annotations.append(mapView.userLocation)
    mapView.showAnnotations(annotations, animated: true)
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
