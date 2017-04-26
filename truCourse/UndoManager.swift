//
//  UndoManager.swift
//  truCourse
//
//  Created by Mike Mayer on 4/25/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import Foundation

protocol UndoableAction : class
{
  func undo() -> Void
  func redo() -> Void
}

class UndoManager
{
  // MARK: - Class methods
  
  static let shared = UndoManager()
  
  private var undoStack = [UndoableAction]()
  private var redoStack = [UndoableAction]()
  
  init() {}
  
  var hasUndo : Bool { return undoStack.isEmpty == false }
  var hasRedo : Bool { return redoStack.isEmpty == false }
  
  func clear() -> Void
  {
    undoStack.removeAll()
    redoStack.removeAll()
  }
  
  func add(_ action : UndoableAction) -> Void
  {
    undoStack.append(action)
    redoStack.removeAll()
  }
  
  func undo() -> Void
  {
    if undoStack.isEmpty == false
    {
      let action = undoStack.removeLast()
      redoStack.append(action)
    
      action.undo()
    }
  }
  
  func redo() -> Void
  {
    if redoStack.isEmpty == false
    {
      let action = redoStack.removeLast()
      undoStack.append(action)
      
      action.redo()
    }
  }
  
  func cancel(undo action:UndoableAction)
  {
    if redoStack.last === action { undoStack.append(redoStack.removeLast()) }
    else                         { redoStack.removeAll()                    }
  }
  
}
