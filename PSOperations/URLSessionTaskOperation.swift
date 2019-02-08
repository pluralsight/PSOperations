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

    fileprivate var observerRemoved = false
    fileprivate let stateLock = NSLock()

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

        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)

        task.resume()
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &URLSessionTaskOperationKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        guard let object = object else { return }

        stateLock.withCriticalScope {
            if object as AnyObject === task && keyPath == "state" && !observerRemoved {
                switch task.state {
                case .completed:
                    finish()
                    fallthrough
                case .canceling:
                    observerRemoved = true
                    task.removeObserver(self, forKeyPath: "state")
                default:
                    return
                }
            }
        }
    }
}
