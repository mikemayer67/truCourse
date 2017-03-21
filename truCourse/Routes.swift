//
//  Routes.swift
//  truCourse
//
//  Created by Mike Mayer on 3/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation

fileprivate func routeDataFilename() throws -> URL
{
  var path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  path.appendPathComponent("routes")
  return path
}

class Routes
{
  var routes  = [Route]()
  var working : Route?
  
  init()
  {
    do
    {
      let path = try routeDataFilename()
      if let rawData = NSArray(contentsOf: path) as? [NSDictionary]
      {
        for routeData in rawData
        {
          let route = Route(with:routeData)
          
          if route.lastSaved == nil
          {
            guard working == nil else { fatalError("Saved data contains multiple routes in progress") }
            working = route
          }
          if route.lastSaved != nil
          {
            routes.append(route)
          }
        }
      }
    }
    catch {}
    
    if working==nil && routes.isEmpty
    {
      working = Route()
    }
  }
  
  func saveData()
  {
    let data = NSMutableArray()
    
    working?.save(into:data)
        
    for route in routes
    {
      route.save(into:data)
    }
    
    do
    {
      let path = try routeDataFilename()
      data.write(to: path, atomically: true)
    }
    catch
    {
      fatalError("Unable to save route data")
    }
  }
}
