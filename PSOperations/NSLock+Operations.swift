/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension to NSLock to simplify executing critical code.
*/

import Foundation

extension Lock {
    func withCriticalScope<T>(_ block: @noescape (Void) -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension RecursiveLock {
    func withCriticalScope<T>(_ block: @noescape (Void) -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
