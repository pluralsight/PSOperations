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

    private let startHandler: ((Operation) -> Void)?
    private let cancelHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Foundation.Operation) -> Void)?
    private let finishHandler: ((Operation, [Error]) -> Void)?

    public init(startHandler: ((Operation) -> Void)? = nil, cancelHandler: ((Operation) -> Void)? = nil, produceHandler: ((Operation, Foundation.Operation) -> Void)? = nil, finishHandler: ((Operation, [Error]) -> Void)? = nil) {
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

    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        finishHandler?(operation, errors)
    }
}
