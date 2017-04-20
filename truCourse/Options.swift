//
//  Options.swift
//  truCourse
//
//  Created by Mike Mayer on 2/23/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import MapKit

class Options
{
  // MARK: - Class data
  
  static let factoryDefaults : [ String : AnyObject ] =
    {
      let fd = Bundle.main.path(forResource: "FactoryDefaults", ofType: "plist")
      return NSDictionary(contentsOfFile:fd!) as! [String : AnyObject]
  }()
  
  static let factoryStatics : [ String : AnyObject ] =
    {
      let fd = Bundle.main.path(forResource: "FactoryStatics", ofType: "plist")
      return NSDictionary(contentsOfFile:fd!) as! [String : AnyObject]
  }()
  
  static let defaults : UserDefaults =
    {
      let ud = UserDefaults.standard
      ud.register(defaults: factoryDefaults)
      ud.synchronize()
      return ud
  }()
  
  static var shared = Options()
  {
    didSet
    {
      shared.declination = oldValue.declination
      shared.updateDefaults()
      defaults.synchronize()
    }
  }
  
  // MARK: - Options Data
  
  var declination      : CLLocationDegrees?
  
  var mapType          : MKMapType
  var showScale        : Bool
  var northType        : NorthType
  var baseUnit         : BaseUnitType
  var locAccFrac       : Double         // used with baseUnit to determine location accuracy
  var postSepFrac      : Double
  var canShakeUndo     : Bool
  var shakeUndoTimeout : Double?
  
  var emailAddress     : String?
  
  var locationAccuracy : CLLocationAccuracy
  {
    var min : Double!
    var max : Double!
    switch baseUnit
    {
    case .English:
      min =   5.0 * 0.3048
      max = 500.0 * 0.3048
    case .Metric:
      min = 1.0
      max = 250.0
    }
    
    return min * exp((1.0-locAccFrac)*log(max/min))
  }
  
  var minPostSeparation : CLLocationDistance
  {
    var min : Double!
    var max : Double!
    switch baseUnit
    {
    case .English:
      min =      5.0 * 0.3048 //  5 feet
      max =  52800.0 * 0.3048 // 10 miles
    case .Metric:
      min = 1.0
      max = 5000.0
    }
    
    return min * exp((postSepFrac)*log(max/min))
  }
  
  var locationAccuracyString : String
  {
    return distanceString(for:self.locationAccuracy)
  }
  
  var minPostSeparationString : String
  {
    return distanceString(for:self.minPostSeparation)
  }
  
  func distanceString(for distance:Double) -> String
  {
    let formatter = MKDistanceFormatter()
    switch baseUnit
    {
    case .English: formatter.units = .imperial
    case .Metric:  formatter.units = .metric
    }
    return formatter.string(fromDistance: distance)
  }

  var locationFilter : CLLocationDistance
  {
    return 2.0 * locationAccuracy
  }
  
  init()
  {
    let dv = Options.defaults
    mapType          = MKMapType(         rawValue: UInt(dv.integer(forKey: "mapType" )))!
    showScale        = dv.bool(forKey: "  showScale")
    northType        = NorthType(         rawValue: dv.integer(forKey: "northType"     ))!
    baseUnit         = BaseUnitType(      rawValue: dv.integer(forKey: "baseUnit"      ))!
    locAccFrac       = dv.double(forKey: "locationAccuracyFrac")
    postSepFrac      = dv.double(forKey: "postSeparationFrac")
    canShakeUndo     = dv.bool(forKey:   "shakeUndo")
    shakeUndoTimeout = dv.double(forKey: "shakeUndoTimeout")
    
    emailAddress = Options.defaults.string(forKey: "emailAddress")
  }
  
  func updateDefaults()
  {
    let dv = Options.defaults
    
    dv.set( mapType.rawValue,        forKey: "mapType"              )
    dv.set( showScale,               forKey: "showScale"            )
    dv.set( northType.rawValue,      forKey: "northType"            )
    dv.set( baseUnit.rawValue,       forKey: "baseUnit"             )
    dv.set( locAccFrac,              forKey: "locationAccuracyFrac" )
    dv.set( postSepFrac,             forKey: "postSeparationFrac"   )
    dv.set( canShakeUndo,            forKey: "shakeUndo"            )
    
    if shakeUndoTimeout == nil
    {
      dv.removeObject(forKey: "shakeUndoTimeout")
    }
    else
    {
      dv.set( shakeUndoTimeout!, forKey: "shakeUndoTimeout" )
    }
    
    if emailAddress == nil
    {
      Options.defaults.removeObject(forKey: "emailAddress")
    }
    else
    {
      Options.defaults.set(NSString(string:emailAddress!), forKey: "emailAddress")
    }
  }
  
  func setEmailAddress(_ address:String?)
  {
    let regex_pattern = "^[a-z0-9._%+-]+@[a-z0-9.-]+[.][a-z]{2,4}$"
    let regex = try! NSRegularExpression(pattern: regex_pattern, options: [.caseInsensitive])
    
    self.emailAddress = nil
    
    if let x = address, x.isEmpty == false
    {
      let range = NSMakeRange(0,NSString(string:x).length)
      if regex.numberOfMatches(in: x, options:[], range:range) == 1
      {
        self.emailAddress = x
      }
    }
  }
  
  func differ(from x:Options) -> Bool
  {
    if mapType          != x.mapType      { return true }
    if showScale        != x.showScale    { return true }
    if northType        != x.northType    { return true }
    if baseUnit         != x.baseUnit     { return true }
    if locAccFrac       != x.locAccFrac   { return true }
    if postSepFrac      != x.postSepFrac  { return true }
    if canShakeUndo     != x.canShakeUndo { return true }
    if shakeUndoTimeout != x.shakeUndoTimeout { return true }
    
    if (emailAddress != nil || x.emailAddress != nil) && (emailAddress != x.emailAddress) { return true }
    
    return false
  }
}
