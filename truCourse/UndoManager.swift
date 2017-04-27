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
  func undo() -> Bool
  func redo() -> Bool
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
      
      if action.undo()
      {
        redoStack.append(action)
      }
    }
  }
  
  func redo() -> Void
  {
    if redoStack.isEmpty == false
    {
      let action = redoStack.removeLast()
      
      if action.redo()
      {
        undoStack.append(action)
      }
      else
      {
        redoStack.removeAll()
      }
    }
  }
  
  func cancel(undo action:UndoableAction)
  {
    if redoStack.last === action { undoStack.append(redoStack.removeLast()) }
    else                         { redoStack.removeAll()                    }
  }
  
}
