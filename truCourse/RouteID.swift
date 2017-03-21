//
//  RouteID.swift
//  truCourse
//
//  Created by Mike Mayer on 3/21/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation


fileprivate func routeIndexFilename() throws -> URL
{
  var path = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  path.appendPathComponent("routeID")
  return path
}

fileprivate var _nextRouteID : Int?

extension Route
{
  static var nextRouteID : Int
  {
    get
    {
      if _nextRouteID == nil
      {
        do
        {
          let path = try routeIndexFilename()
          let data = NSDictionary(contentsOf: path)
          _nextRouteID = data?.value(forKey: "nextRouteID") as? Int
        }
        catch {}
      }
      if _nextRouteID == nil { _nextRouteID = 1 }

      return _nextRouteID!
    }
    
    set
    {
      if _nextRouteID == nil || newValue > _nextRouteID!
      {
        _nextRouteID = newValue
        do
        {
          let path = try routeIndexFilename()
          let data = NSMutableDictionary()
          data.setValue(_nextRouteID, forKey:"nextRouteID")
          data.write(to: path, atomically: true)
        }
        catch {}
      }
    }
  }
}
