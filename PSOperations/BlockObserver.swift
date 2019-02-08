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
public class BlockObserver: OperationObserver {
    // MARK: Properties

    fileprivate let startHandler: ((Operation) -> Void)?
    fileprivate let cancelHandler: ((Operation) -> Void)?
    fileprivate let produceHandler: ((Operation, Foundation.Operation) -> Void)?
    fileprivate let finishHandler: ((Operation, [NSError]) -> Void)?

    public init(startHandler: ((Operation) -> Void)? = nil, cancelHandler: ((Operation) -> Void)? = nil, produceHandler: ((Operation, Foundation.Operation) -> Void)? = nil, finishHandler: ((Operation, [NSError]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.cancelHandler = cancelHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }

    // MARK: OperationObserver

    public func operationDidStart(_ operation: Operation) {
        startHandler?(operation)
    }

    public func operationDidCancel(_ operation: Operation) {
        cancelHandler?(operation)
    }

    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) {
        produceHandler?(operation, newOperation)
    }

    public func operationDidFinish(_ operation: Operation, errors: [NSError]) {
        finishHandler?(operation, errors)
    }
}
