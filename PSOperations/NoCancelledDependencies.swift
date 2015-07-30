/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import Foundation

/**
    A condition that specifies that every dependency must have succeeded.
    If any dependency was cancelled, the target operation will be cancelled as 
    well.
*/
public struct NoCancelledDependencies: OperationCondition {
    public static let name = "NoCancelledDependencies"
    static let cancelledDependenciesKey = "CancelledDependencies"
    public let isMutuallyExclusive = false
    
    public init() {
        // No op.
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        // Verify that all of the dependencies executed.
        let cancelled = operation.dependencies.filter {
            if let dependency = $0 as? Operation {
                return dependency.cancelled
            }
            
            return true
        }

        if !cancelled.isEmpty {
            // At least one dependency was cancelled; the condition was not satisfied.
            let error = NSError(code: .ConditionFailed, userInfo: [
                OperationConditionKey: self.dynamicType.name,
                self.dynamicType.cancelledDependenciesKey: cancelled
            ])
            
            completion(.Failed(error))
        }
        else {
            completion(.Satisfied)
        }
    }
}
