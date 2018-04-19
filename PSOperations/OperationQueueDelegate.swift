//
//  OperationQueueDelegate.swift
//  PSOperations
//
//  Created by Matt McMurry on 4/9/18.
//  Copyright © 2018 Pluralsight. All rights reserved.
//

import Foundation

/**
 The delegate of an `OperationQueue` can respond to `Operation` lifecycle
 events by implementing these methods.
 
 In general, implementing `OperationQueueDelegate` is not necessary; you would
 want to use an `OperationObserver` instead. However, there are a couple of
 situations where using `OperationQueueDelegate` can lead to simpler code.
 For example, `GroupOperation` is the delegate of its own internal
 `OperationQueue` and uses it to manage dependencies.
 */
@objc public protocol OperationQueueDelegate: NSObjectProtocol {
    @objc optional func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Foundation.Operation)
    @objc optional func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Foundation.Operation, withErrors errors: [NSError])
}
