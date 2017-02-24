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
  
  var northType       : NorthType
  var baseUnit        : BaseUnitType
  var trackingEnabled : Bool
  var headingUp       : Bool
  
  var trackingMode : MKUserTrackingMode
  {
    return ( trackingEnabled ? (headingUp ? .followWithHeading : .follow) : .none );
  }
  
  var headingAvailable  : Bool
  
  var emailAddress : String?
  
  init()
  {
    let dv = Options.defaults
    northType       = NorthType(         rawValue: dv.integer(forKey: "northType"   ))!
    baseUnit        = BaseUnitType(      rawValue: dv.integer(forKey: "baseUnit"    ))!
    trackingEnabled = dv.bool(forKey: "trackingEnabled")
    headingUp       = dv.bool(forKey: "headingUp")
    
    emailAddress = Options.defaults.string(forKey: "emailAddress")
    
    headingAvailable =  CLLocationManager.headingAvailable()
  }
  
  func updateDefaults()
  {
    let dv = Options.defaults
    dv.set(    northType.rawValue, forKey:"northType"       )
    dv.set(     baseUnit.rawValue, forKey:"baseUnit"        )
    dv.set(       trackingEnabled, forKey:"trackingEnabled" )
    dv.set(             headingUp, forKey:"headingUp"       )
    
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
    if northType != x.northType { return true }
    if baseUnit  != x.baseUnit  { return true }
    if trackingEnabled != x.trackingEnabled { return true }
    if headingUp != x.headingUp { return true }
    
    if (emailAddress != nil || x.emailAddress != nil) && (emailAddress != x.emailAddress) { return true }
    
    return false
  }
}
