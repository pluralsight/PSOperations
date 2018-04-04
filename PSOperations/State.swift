//
//  State.swift
//  PSOperations
//
//  Created by Matt McMurry on 6/23/17.
//  Copyright © 2017 Pluralsight. All rights reserved.
//

import Foundation

internal enum State: Int, Comparable {
    
    static func <(lhs: State, rhs: State) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    static func ==(lhs: State, rhs: State) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    
    /// The initial state of an `Operation`.
    case initialized
    
    /// The `Operation` is ready to begin evaluating conditions.
    case pending
    
    /// The `Operation` is evaluating conditions.
    case evaluatingConditions
    
    /**
     The `Operation`'s conditions have all been satisfied, and it is ready
     to execute.
     */
    case ready
    
    /// The `Operation` is executing.
    case executing
    
    /// The `Operation` has finished executing.
    case finished
    
    func canTransitionToState(_ target: State, operationIsCancelled cancelled: Bool) -> Bool {
        switch (self, target) {
        case (.initialized, .pending):
            return true
        case (.pending, .evaluatingConditions):
            return true
        case (.pending, .finished): // where cancelled:
            return true
        case (.pending, .ready):
            return true
        case (.evaluatingConditions, .ready):
            return true
        case (.evaluatingConditions, .finished): // where cancelled:
            return true
        case (.ready, .executing):
            return true
        case (.ready, .finished):
            return true
        case (.executing, .finished):
            return true
        default:
            return false
        }
    }
}
