/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    `TimeoutObserver` is a way to make an `Operation` automatically time out and 
    cancel after a specified time interval.
*/
public struct TimeoutObserver: OperationObserver {
    // MARK: Properties

    static let timeoutKey = "Timeout"
    
    private let timeout: TimeInterval
    
    // MARK: Initialization
    
    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(_ operation: Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        let when = DispatchTime.now() + Double(Int64(timeout * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

        DispatchQueue.global().after(when: when) {
            /*
                Cancel the operation if it hasn't finished and hasn't already 
                been cancelled.
            */
            if !operation.isFinished && !operation.isCancelled {
                let error = NSError(code: .executionFailed, userInfo: [
                    self.dynamicType.timeoutKey: self.timeout
                ])

                operation.cancelWithError(error)
            }
        }
    }
    
    public func operationDidCancel(_ operation: Operation) {
        // No op.
    }

    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) {
        // No op.
    }

    public func operationDidFinish(_ operation: Operation, errors: [NSError]) {
        // No op.
    }
}
