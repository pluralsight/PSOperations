//
//  Atomic.swift
//  PSOperations
//
//  Created by Matt McMurry on 3/31/18.
//  Copyright © 2018 Pluralsight. All rights reserved.
//

import Foundation

public final class Atomic<T> {
    
    private var _value: T
    private let lock = NSLock()
    
    public var value: T {
        get {
            lock.lock()
            let value = _value
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            _value = newValue
            lock.unlock()
        }
    }
    
    init(value: T) {
        _value = value
    }
    
    public func modify(_ modify: (inout T) -> ()) {
        lock.lock()
        modify(&_value)
        lock.unlock()
    }
    
    @discardableResult
    public func swap(_ value: T) -> T {
        lock.lock()
        let current = _value
        _value = value
        lock.unlock()
        return current
    }
    
    public func with<U>(_ value: (T) -> U) -> U {
        lock.lock()
        let returnValue = value(_value)
        lock.unlock()
        return returnValue
    }
}
