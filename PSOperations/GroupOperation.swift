/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how operations can be composed together to form new operations.
*/

import Foundation

/**
    A subclass of `Operation` that executes zero or more operations as part of its
    own execution. This class of operation is very useful for abstracting several 
    smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
    is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.

    Additionally, `GroupOperation`s are useful if you establish a chain of dependencies, 
    but part of the chain may "loop". For example, if you have an operation that
    requires the user to be authenticated, you may consider putting the "login" 
    operation inside a group operation. That way, the "login" operation may produce
    subsequent operations (still within the outer `GroupOperation`) that will all
    be executed before the rest of the operations in the initial chain of operations.
*/
open class GroupOperation: Operation {
    fileprivate let internalQueue = OperationQueue()
    fileprivate let startingOperation = Foundation.BlockOperation(block: {})
    fileprivate let finishingOperation = Foundation.BlockOperation(block: {})

    private var _aggregatedErrors: [NSError] = []
    private let aggregateQueue = DispatchQueue(label: "Operations.GroupOperations.aggregateErrors")
    fileprivate var aggregatedErrors: [NSError] {
        get {
            var errors: [NSError] = []
            aggregateQueue.sync {
                errors = _aggregatedErrors
            }
            return errors
        }
        set {
            aggregateQueue.sync {
                self._aggregatedErrors = newValue
            }
        }
    }

    public convenience init(operations: Foundation.Operation...) {
        self.init(operations: operations)
    }

    public init(operations: [Foundation.Operation]) {
        super.init()

        internalQueue.isSuspended = true
        internalQueue.delegate = self
        internalQueue.addOperation(startingOperation)

        for operation in operations {
            internalQueue.addOperation(operation)
        }
    }

    override open func cancel() {
        internalQueue.cancelAllOperations()
        internalQueue.isSuspended = false
        super.cancel()
    }

    override open func execute() {
        internalQueue.isSuspended = false
        internalQueue.addOperation(finishingOperation)
    }

    open func addOperation(_ operation: Foundation.Operation) {
        internalQueue.addOperation(operation)
    }

    /**
        Note that some part of execution has produced an error.
        Errors aggregated through this method will be included in the final array 
        of errors reported to observers and to the `finished(_:)` method.
    */
    public final func aggregateError(_ error: NSError) {
        aggregatedErrors.append(error)
    }

    open func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {
        // For use by subclassers.
    }
}

extension GroupOperation: OperationQueueDelegate {
    public final func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Foundation.Operation) {
        assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")

        /*
            Some operation in this group has produced a new operation to execute.
            We want to allow that operation to execute before the group completes,
            so we'll make the finishing operation dependent on this newly-produced operation.
        */
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }

        /*
        All operations should be dependent on the "startingOperation".
        This way, we can guarantee that the conditions for other operations
        will not evaluate until just before the operation is about to run.
        Otherwise, the conditions could be evaluated at any time, even
        before the internal operation queue is unsuspended.
        */
        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
    }

    public final func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Foundation.Operation, withErrors errors: [NSError]) {
        aggregatedErrors.append(contentsOf: errors)

        if operation === finishingOperation {
            internalQueue.isSuspended = true
            finish(aggregatedErrors)
        } else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
