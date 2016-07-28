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
public class URLSessionTaskOperation: Operation {
    let task: URLSessionTask
    
    private var observerRemoved = false
    private let stateLock = Lock()
    
    public init(task: URLSessionTask) {
        assert(task.state == .suspended, "Tasks must be suspended.")
        self.task = task
        super.init()
        
        addObserver(BlockObserver(cancelHandler: { _ in
            task.cancel()
        }))
    }
    
    override public func execute() {
        assert(task.state == .suspended, "Task was resumed by something other than \(self).")

        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)
        
        task.resume()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == &URLSessionTaskOperationKVOContext else { return }
        
        stateLock.withCriticalScope {
            if object === task && keyPath == "state" && !observerRemoved {
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
