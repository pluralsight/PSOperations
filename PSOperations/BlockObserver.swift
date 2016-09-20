/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    The `BlockObserver` is a way to attach arbitrary blocks to significant events 
    in an `Operation`'s lifecycle.
*/
public struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    fileprivate let startHandler: ((PSOperation) -> Void)?
    fileprivate let cancelHandler: ((PSOperation) -> Void)?
    fileprivate let produceHandler: ((PSOperation, Foundation.Operation) -> Void)?
    fileprivate let finishHandler: ((PSOperation, [NSError]) -> Void)?
    
    public init(startHandler: ((PSOperation) -> Void)? = nil, cancelHandler: ((PSOperation) -> Void)? = nil, produceHandler: ((PSOperation, Foundation.Operation) -> Void)? = nil, finishHandler: ((PSOperation, [NSError]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.cancelHandler = cancelHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(_ operation: PSOperation) {
        startHandler?(operation)
    }
    
    public func operationDidCancel(_ operation: PSOperation) {
        cancelHandler?(operation)
    }
    
    public func operation(_ operation: PSOperation, didProduceOperation newOperation: Foundation.Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(_ operation: PSOperation, errors: [NSError]) {
        finishHandler?(operation, errors)
    }
}
