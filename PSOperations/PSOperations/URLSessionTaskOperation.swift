/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to lift operation-like objects in to the NSOperation world.
*/

import Foundation

private var URLSessionTaksOperationKVOContext = 0

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
    let task: NSURLSessionTask
    
    public init(task: NSURLSessionTask) {
        assert(task.state == .Suspended, "Tasks must be suspended.")
        self.task = task
        super.init()
    }
    
    override public func execute() {
        assert(task.state == .Suspended, "Task was resumed by something other than \(self).")

        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions.allZeros, context: &URLSessionTaksOperationKVOContext)
        
        task.resume()
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context != &URLSessionTaksOperationKVOContext {
            return
        }
        
        if object === task && keyPath == "state" && task.state == .Completed {
            task.removeObserver(self, forKeyPath: "state")
            finish()
        }
    }
    
    override public func cancel() {
        task.cancel()
        super.cancel()
    }
}
