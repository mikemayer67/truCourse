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
  
  private(set) var routes  = [Route]()
  
  init() {}
  
  init(load file:URL)
  {
    if let routesData = NSArray(contentsOf: file) as? [NSDictionary]
    {
      for routeData in routesData
      {
        let route = Route(with:routeData)
        routes.append(route)
      }
    }
  }
  
  func save(to file:URL)
  {
    let data = NSMutableArray()
    
    routes.forEach { $0.save(into:data) }
    
    data.write(to: file, atomically: true)
  }
}
