/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to lift operation-like objects in to the NSOperation world.
*/

import Foundation

private var URLSessionTaskOperationKVOContext = 0

/**
    `URLSessionTaskOperation` is an `Operation` that lifts an `NSURLSessionTask` 
    into an operation.

    Note that this operation does not participate in any of the delegate callbacks \
    of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
    task has been completed. It also does not get notified about any errors that
    occurred during execution of the task.

    An example usage of `URLSessionTaskOperation` can be seen in the `DownloadEarthquakesOperation`.
*/
open class URLSessionTaskOperation: Operation {
    let task: URLSessionTask

    private var stateObservation: NSKeyValueObservation?
    private var observerRemoved = false
    private let stateLock = NSLock()

    deinit {
        stateObservation?.invalidate()
    }
    
    public init(task: URLSessionTask) {
        assert(task.state == .suspended, "Tasks must be suspended.")
        self.task = task
        super.init()

        addObserver(BlockObserver(cancelHandler: { _ in
            task.cancel()
        }))
    }

    override open func execute() {
        assert(task.state == .suspended, "Task was resumed by something other than \(self).")

        stateObservation = task.observe(\.state) { [weak self] _, _ in
            self?.stateChange()
        }
        task.resume()
    }

    private func stateChange() {
        stateLock.withCriticalScope {
            if !observerRemoved {
                switch task.state {
                case .completed:
                    finish()
                    fallthrough
                case .canceling:
                    observerRemoved = true
                    stateObservation?.invalidate()
                default:
                    return
                }
            }
        }
    }
}
