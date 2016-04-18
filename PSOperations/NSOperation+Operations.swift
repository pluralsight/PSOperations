/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to Foundation.NSOperation.
*/

import Foundation

extension NSOperation {
    /** 
        Add a completion block to be executed after the `NSOperation` enters the
        "finished" state.
    */
    func addCompletionBlock(block: Void -> Void) {
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
    func addDependencies(dependencies: [NSOperation]) {
        for dependency in dependencies {
            addDependency(dependency)
        }
    }
}

extension NSOperation {

    /**
     Special case handling for fetching `OperationDebugData` on an `NSOperation`. Ideally this extension
     would just conform to the `OperationDebuggable` protocol and implement `debugData()`, but swift
     currently doesn't allow method overrides when extensions are involved. By making `NSOperation`
     implement `debugData` this would prevent all subclasses from implementing it (`Operation` and
     `GroupOperation`). To get around this we are adding a special method just for `NSOperation` and
     the debug generation code needs to have specific handling for it.
     */
    public func debugDataNSOperation() -> OperationDebugData {
        return OperationDebugData(
            description: "NSOperation: \(String(self))",
            properties: [
                "cancelled": String(self.cancelled),
                "ready": String(self.ready),
                "executing": String(self.executing),
                "finished": String(self.finished),
                "QOS": self.qualityOfService.stringRepresentation()
            ],
            conditions: [],
            dependencies: self.dependencies.map { ($0 as? OperationDebuggable)?.debugData() ?? $0.debugDataNSOperation()})
    }
    
}
