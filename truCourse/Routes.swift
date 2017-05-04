//
//  Routes.swift
//  truCourse
//
//  Created by Mike Mayer on 3/17/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation



class Routes
{
  static var shared : Routes!
  {
    willSet
    {
      guard shared == nil else { fatalError("Internal coding error... should only be set once!") }
    }
  }
  
  private(set) var routes  = [Int:Route]()
  
  init() {}
  
  init(load file:URL)
  {
    if let routesData = NSArray(contentsOf: file) as? [NSDictionary]
    {
      for routeData in routesData
      {
        let route = Route(with:routeData)
        routes[route.routeID] = route
      }
    }
  }
  
  func save(to file:URL)
  {
    let data = NSMutableArray()
    
    routes.forEach { (_,route) in route.save(into:data) }
    
    data.write(to: file, atomically: true)
  }
  
  func add(_ route : Route)
  {
    routes[route.routeID] = route
    
    save(to:DataController.routesDataFile)
  }
  
  subscript(id:Int) -> Route?
  {
    get { return routes[id] }
  }
}
