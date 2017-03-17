//
//  Notification+extension.swift
//  truCourse
//
//  Created by Mike Mayer on 3/16/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation

extension Notification
{
  static func enqueue(_ key: NotificationName,
                     postingStyle: NotificationQueue.PostingStyle,
                     object:Any? = nil,
                     userInfo: [AnyHashable : Any]? = nil )
  {
    NotificationQueue.default.enqueue (
      Notification(name: Notification.Name(rawValue: key.rawValue), object:object, userInfo:userInfo),
      postingStyle:postingStyle )
  }
  
  static func enqueue(_ key: NotificationName,
                      postingStyle: NotificationQueue.PostingStyle,
                      coalesceMask: NotificationQueue.NotificationCoalescing,
                      forModes modes: [RunLoopMode]? = nil,
                      object:Any? = nil,
                      userInfo: [AnyHashable : Any]? = nil )
  {
    NotificationQueue.default.enqueue (
      Notification(name: Notification.Name(rawValue: key.rawValue), object:object, userInfo:userInfo),
      postingStyle:postingStyle,
      coalesceMask:coalesceMask,
      forModes: modes)
  }
  
  static func enqueue(_ name: String,
                      postingStyle: NotificationQueue.PostingStyle,
                      object:Any? = nil,
                      userInfo: [AnyHashable : Any]? = nil )
  {
    NotificationQueue.default.enqueue (
      Notification(name: Notification.Name(rawValue: name), object:object, userInfo:userInfo),
      postingStyle:postingStyle )
  }
  
  static func enqueue(_ name: String,
                      postingStyle: NotificationQueue.PostingStyle,
                      coalesceMask: NotificationQueue.NotificationCoalescing,
                      forModes modes: [RunLoopMode]? = nil,
                      object:Any? = nil,
                      userInfo: [AnyHashable : Any]? = nil )
  {
    NotificationQueue.default.enqueue (
      Notification(name: Notification.Name(rawValue: name), object:object, userInfo:userInfo),
      postingStyle:postingStyle,
      coalesceMask:coalesceMask,
      forModes: modes)
  }
  
  static func observe(_ key: NotificationName,
                      object obj: Any?,
                      using block: @escaping (Notification) -> Void) -> NSObjectProtocol
  {
    return
      NotificationCenter.default.addObserver( forName: Notification.Name(rawValue: key.rawValue),
                                              object: obj,
                                              queue: nil,
                                              using: block )
  }
  
  static func observe(_ observer: Any,
                      selector aSelector: Selector,
                      key: NotificationName,
                      object anObject: Any?)
  {
    NotificationCenter.default.addObserver(observer,
                                           selector: aSelector,
                                           name: Notification.Name(rawValue:key.rawValue),
                                           object: anObject )
  }
  
  static func observe(_ name: String,
                      object obj: Any?,
                      using block: @escaping (Notification) -> Void) -> NSObjectProtocol
  {
    return
      NotificationCenter.default.addObserver( forName: Notification.Name(rawValue:name),
                                              object: obj,
                                              queue: nil,
                                              using: block )
  }
  
  static func observe(_ observer: Any,
                      selector aSelector: Selector,
                      name: String,
                      object anObject: Any?)
  {
    NotificationCenter.default.addObserver(observer,
                                           selector: aSelector,
                                           name: Notification.Name(rawValue:name),
                                           object: anObject )
  }
}
