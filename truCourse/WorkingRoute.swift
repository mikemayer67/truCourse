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
  
  override var saveDirtyState : Bool { return true }

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
    
    UndoManager.shared.clear()
  }
  
  override init( from ref : Route )
  {
    super.init(from: ref)
  }
  
  func save()
  {
    let data = routeData()
    let file = DataController.workingDataFile
    
    data.write(to:file, atomically:true)
  }
  
  override func save(withNewID: Bool)
  {
    super.save(withNewID: withNewID)
    self.save()
  }
  
  override var dirty : Bool
  {
    didSet { if dirty { self.save() } }
  }
}
