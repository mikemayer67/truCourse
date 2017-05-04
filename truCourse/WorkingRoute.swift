//
//  WorkingRoute.swift
//  truCourse
//
//  Created by Mike Mayer on 4/30/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation

class WorkingRoute : Route
{
  override init() { super.init() }
  
  init(load file:URL)
  {
    if let routeData = NSDictionary(contentsOf: file)
    {
      super.init(with: routeData)
      Options.shared.declination = declination
    }
    else
    {
      super.init()
    }
  }
  
  func save()
  {
    let data = routeData()
    let file = DataController.workingDataFile
    
    data.write(to:file, atomically:true)
  }
  
  override var dirty : Bool
  {
    didSet { self.save() }
  }
}
