//
//  Options.swift
//  truCourse
//
//  Created by Mike Mayer on 2/23/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation
import MapKit

struct Options
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
  
  static func commit()
  {
    defaults.synchronize()
  }
  
  // MARK: - Options Data
  
  var topOfScreen     : MapOrientation
  var headingAccuracy : HeadingAccuracy  // map orientation update frequency
  var mapType         : MKMapType
  var northType       : NorthType
  var baseUnit        : BaseUnitType
  var locAccFrac      : Double         // used with baseUnit to determine location accuracy
  
  var emailAddress    : String?
  
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
  
  var locationAccuracyString : String
  {
    let formatter = MKDistanceFormatter()
    switch baseUnit
    {
    case .English: formatter.units = .imperial
    case .Metric:  formatter.units = .metric
    }
    return formatter.string(fromDistance: self.locationAccuracy)
  }

  var locationFilter : CLLocationDistance
  {
    return 2.0 * locationAccuracy
  }
  
  var trackingMode : MKUserTrackingMode
  {
    switch(topOfScreen)
    {
    case .North:   return .follow
    case .Heading: return .followWithHeading
    }
  }
  
  var headingFilter : CLLocationDegrees
  {
    return headingAccuracy.rawValue
  }
  
  init()
  {
    let dv = Options.defaults
    topOfScreen     = MapOrientation(    rawValue: dv.integer(forKey: "topOfScreen"   ))!
    mapType         = MKMapType(         rawValue: UInt(dv.integer(forKey: "mapType" )))!
    northType       = NorthType(         rawValue: dv.integer(forKey: "northType"     ))!
    baseUnit        = BaseUnitType(      rawValue: dv.integer(forKey: "baseUnit"      ))!
    locAccFrac      = dv.double(forKey: "locationAccuracyFrac")
    
    headingAccuracy = .Good
    headingAccuracy.set(byIndex: dv.integer(forKey: "headingAccuracy"))
    
    emailAddress = Options.defaults.string(forKey: "emailAddress")
  }
  
  func updateDefaults()
  {
    let dv = Options.defaults
    
    dv.set( topOfScreen.rawValue,    forKey: "topOfScreen"          )
    dv.set( mapType.rawValue,        forKey: "mapType"              )
    dv.set( northType.rawValue,      forKey: "northType"            )
    dv.set( baseUnit.rawValue,       forKey: "baseUnit"             )
    dv.set( locAccFrac,              forKey: "locationAccuracyFrac" )
    
    dv.set( headingAccuracy.index(), forKey: "headingAccuracy"      )
    
    if emailAddress == nil
    {
      Options.defaults.removeObject(forKey: "emailAddress")
    }
    else
    {
      Options.defaults.set(NSString(string:emailAddress!), forKey: "emailAddress")
    }
  }
  
  mutating func setEmailAddress(_ address:String?)
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
    if topOfScreen != x.topOfScreen { return true }
    if mapType     != x.mapType     { return true }
    if northType   != x.northType   { return true }
    if baseUnit    != x.baseUnit    { return true }
    if locAccFrac  != x.locAccFrac  { return true }
    
    if headingAccuracy != x.headingAccuracy { return true }
    
    if (emailAddress != nil || x.emailAddress != nil) && (emailAddress != x.emailAddress) { return true }
    
    return false
  }
}
