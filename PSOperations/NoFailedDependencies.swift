//
//  NoFailedDependencies.swift
//  PSOperations
//
//  Created by Cezary Wojcik on 4/16/16.
//  Adapted from https://github.com/danthorpe/Operations
//

import Foundation

/**
 A condition that specificed that every dependency of the
 operation must succeed. If any dependency fails/cancels,
 the target operation will be fail.
 */
public struct NoFailedDependencies: OperationCondition {

    /// A constant used to display cancelled dependencies in an error.
    static let cancelledDependenciesKey = "CancelledDependencies"

    /// A constant used to display failed dependencies in an error.
    static let failedDependenciesKey = "FailedDependencies"

    /// A constant name for the condition.
    public static let name = "No Failed Dependencies"

    /// A constant flag indicating this condition is not mutually exclusive
    public static let isMutuallyExclusive = false

    /// Initializer which takes no parameters.
    public init() { }

    /// Conforms to `OperationCondition` but there are no dependent operations.
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    /**
     Evaluates the operation with respect to the finished status of its dependencies.
     The condition first checks if any dependencies were cancelled, and then
     it checks to see if any dependencies failed due to errors.
     The cancelled or failed operations are not associated with the error.
     - parameter operation: the `Operation` which the condition is attached to.
     - parameter completion: the completion block which receives a `OperationConditionResult`.
     */
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let dependencies = operation.dependencies

        let cancelled = dependencies.filter { $0.cancelled }
        let failures = dependencies.filter { ($0 as? Operation)?.failed ?? false }

        if !cancelled.isEmpty || !failures.isEmpty {
            // At least one dependency was cancelled or failed; the condition was not satisfied.

            var userInfo: [String: AnyObject] = [
                OperationConditionKey: NoFailedDependencies.name,
            ]

            if !cancelled.isEmpty {
                userInfo[NoFailedDependencies.cancelledDependenciesKey] = cancelled
            }

            if !failures.isEmpty {
                userInfo[NoFailedDependencies.failedDependenciesKey] = failures
            }

            let error = NSError(code: .ConditionFailed, userInfo: userInfo)

            completion(.Failed(error))
        } else {
            completion(.Satisfied)
        }
    }

}
