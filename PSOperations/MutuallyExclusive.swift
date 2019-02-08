/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import Foundation

/// A generic condition for describing kinds of operations that may not execute concurrently.
public struct MutuallyExclusive<T>: OperationCondition {
    public static var name: String {
        return "MutuallyExclusive<\(T.self)>"
    }

    public static var isMutuallyExclusive: Bool {
        return true
    }

    public init() { }

    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return nil
    }

    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        completion(.satisfied)
    }
}

/**
    The purpose of this enum is to simply provide a non-constructible
    type to be used with `MutuallyExclusive<T>`.
*/
public enum Alert { }

/// A condition describing that the targeted operation may present an alert.
public typealias AlertPresentation = MutuallyExclusive<Alert>
