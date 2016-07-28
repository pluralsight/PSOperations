/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to Foundation.NSOperation.
*/

import Foundation

extension Foundation.Operation {
    /** 
        Add a completion block to be executed after the `NSOperation` enters the
        "finished" state.
    */
    func addCompletionBlock(_ block: (Void) -> Void) {
        if let existing = completionBlock {
            /*
                If we already have a completion block, we construct a new one by
                chaining them together.
            */
            completionBlock = {
                existing()
                block()
            }
        }
        else {
            completionBlock = block
        }
    }

    /// Add multiple depdendencies to the operation.
    func addDependencies(_ dependencies: [Foundation.Operation]) {
        for dependency in dependencies {
            addDependency(dependency)
        }
    }
}
