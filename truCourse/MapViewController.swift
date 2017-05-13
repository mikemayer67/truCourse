//
//  MapViewController.swift
//  truCourse
//
//  Created by Mike Mayer on 2/22/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, DataViewController, MKMapViewDelegate
{
  @IBOutlet weak var mapView        : MKMapView!
  @IBOutlet weak var trackingView   : TrackingView!
    
  private var routeOverlay    : MKOverlay?
  private var candOverlay     : MKOverlay?
  private var postAnnotations = [Int:PostAnnotation]()
  private var postNorth       : NorthType = .True
  private var postUnits       : BaseUnitType = .English
  
  private weak var lastUserView : UIView?
  
  private var candPrevWaypoint : Waypoint?
  
   var hasSelection : Bool         { return false    }
  
  // MARK: - Load/Visibility methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    trackingView.mapViewController = self
    
    mapView.mapType           = .standard
    mapView.showsUserLocation = true
    mapView.setUserTrackingMode(.follow, animated: true)
    mapView.showsScale        = true
    
    trackingView.initTrackingMode(.follow)
    
    mapView.remove { (gr:UIGestureRecognizer)->Bool in return gr is UILongPressGestureRecognizer }
    
    let panGR = UIPanGestureRecognizer(target: trackingView, action: #selector(TrackingView.userDraggedMap(_:)))
    panGR.delegate = trackingView
    mapView.addGestureRecognizer(panGR)
    
    let tapGR = UITapGestureRecognizer(target: trackingView, action: #selector(TrackingView.userDraggedMap(_:)))
    tapGR.numberOfTapsRequired = 1
    tapGR.numberOfTouchesRequired = 2
    tapGR.delegate = trackingView
    mapView.addGestureRecognizer(tapGR)
    
    let dtapGR = UITapGestureRecognizer(target: trackingView, action: #selector(TrackingView.userDraggedMap(_:)))
    dtapGR.numberOfTouchesRequired = 1
    dtapGR.numberOfTapsRequired = 2
    dtapGR.delegate = trackingView
    mapView.addGestureRecognizer(dtapGR)
  }
  
  override func viewWillDisappear(_ animated: Bool)
  {
    super.viewWillDisappear(animated)
    trackingView.pauseAutoScaling()
  }
  
  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    trackingView.resumeAutoScaling()
  }
  
  func handleLocationUpdate()
  {
    guard mapView.isUserLocationVisible else { return }
    
    let uloc = mapView.userLocation
    
    if let uv = mapView.view(for:uloc),
      uv !== lastUserView
    {
      lastUserView = uv
      
      let popup = UILongPressGestureRecognizer(target: self, action: #selector(handleUserPopup(_:)))
      uv.addGestureRecognizer(popup)
    }
  }

  // MARK: - Options
  
  func applyOptions()
  {
    let options = Options.shared
    
    mapView.mapType    = options.mapType
    mapView.showsScale = options.showScale
    
    for (_,post) in postAnnotations { post.updateTitle() }
    
    if options.autoScale { trackingView.resumeAutoScaling() }
    else                 { trackingView.pauseAutoScaling()  }
  }
  
  // MARK: - State
  
  func applyState(_ state: AppState)
  {
    switch state
    {
    case .Uninitialized, .Disabled, .Paused:
      trackingView.paused = true
      mapView.showsUserLocation = false
    default:
      mapView.showsUserLocation = true
      trackingView.paused = false
    }
  }
  
  // MARK: - MapView delegate methods passed through to the TrackingView
  
  func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
  {
    trackingView.userTrackingModeChanged(to:mode)
  }
  
  
  // MARK: - Handled MapView delegate methods
  
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
    guard sender.state == .began else { return }
    
    sender.isEnabled = false  // cancels the long press gesture now that it's recognized
    sender.isEnabled = true   // rather than waiting for user to let go of screen
    
    let postView = sender.view as! MKAnnotationView
    let post     = postView.annotation as! PostAnnotation
    let index    = post.waypoint.index!
    
    let actions = DataController.shared.popupActions(for: index)
    
    if actions == nil { return }
    
    let alert = UIAlertController( title: "Post \(index) selected",
                                   message: "What do you want to do?",
                                   preferredStyle: .actionSheet)
    
    actions!.forEach { alert.addAction($0) }
  
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    self.present(alert, animated:true)
  }
  
  func handleUserPopup(_ sender:UILongPressGestureRecognizer)
  {
    guard sender.state == .began else { return }
    
    sender.isEnabled = false  // cancels the long press gesture now that it's recognized
    sender.isEnabled = true   // rather than waiting for user to let go of screen
    
    DataController.shared.pickInsertionIndex()
  }
  
  // MARK: - Route update
  
  func updateRoute(_ route: Route)
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
    
    trackingView.routeDidChange()
    
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
    
    if cand != nil { updateCandidate(cand!) }
  }
  
  func updateCandidate(_ candidate: Waypoint?)
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
  
  
  func showAllPosts()
  {
    var annotations = [MKAnnotation]()
    postAnnotations.forEach { (_,value) in annotations.append(value) }
    if mapView.showsUserLocation { annotations.append(mapView.userLocation) }
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
