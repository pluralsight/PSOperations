/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file defines the OperationObserver protocol.
*/

import Foundation

/**
    The protocol that types may implement if they wish to be notified of significant
    operation lifecycle events.
*/
public protocol OperationObserver {
    
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(_ operation: PSOperation)
    
    /// Invoked immediately after the first time the `Operation`'s `cancel()` method is called
    func operationDidCancel(_ operation: PSOperation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(_ operation: PSOperation, didProduceOperation newOperation: Foundation.Operation)
    
    /**
        Invoked as an `Operation` finishes, along with any errors produced during
        execution (or readiness evaluation).
    */
    func operationDidFinish(_ operation: PSOperation, errors: [NSError])
    
}
