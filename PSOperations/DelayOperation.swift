/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to make an operation that efficiently waits.
*/

import Foundation

/** 
    `DelayOperation` is an `Operation` that will simply wait for a given time 
    interval, or until a specific `NSDate`.

    It is important to note that this operation does **not** use the `sleep()`
    function, since that is inefficient and blocks the thread on which it is called. 
    Instead, this operation uses `dispatch_after` to know when the appropriate amount 
    of time has passed.

    If the interval is negative, or the `NSDate` is in the past, then this operation
    immediately finishes.
*/
public class DelayOperation: Operation {
    // MARK: Types

    private enum Delay {
        case interval(TimeInterval)
        case date(Foundation.Date)
    }
    
    // MARK: Properties
    
    private let delay: Delay
    
    // MARK: Initialization
    
    public init(interval: TimeInterval) {
        delay = .interval(interval)
        super.init()
    }
    
    public init(until date: Date) {
        delay = .date(date)
        super.init()
    }
    
    override public func execute() {
        let interval: TimeInterval
        
        // Figure out how long we should wait for.
        switch delay {
            case .interval(let theInterval):
                interval = theInterval

            case .date(let date):
                interval = date.timeIntervalSinceNow
        }
        
        guard interval > 0 else {
            finish()
            return
        }
        
        let when = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global().after(when: when) {
            // If we were cancelled, then finish() has already been called.
            if !self.isCancelled {
                self.finish()
            }
        }
    }
}
