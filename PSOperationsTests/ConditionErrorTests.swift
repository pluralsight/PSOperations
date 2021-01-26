//
//  ConditionErrorTests.swift
//  PSOperations
//
//  Created by Matt McMurry on 10/1/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest

class ConditionErrorTests: XCTestCase {
    
    struct TestCondition: OperationCondition {
        static let name = "TestCondition"
        static let isMutuallyExclusive = false
        
        init() {}
        
        func dependencyForOperation(_ operation: PSOperation) -> Foundation.Operation? {
            return nil
        }
        
        func evaluateForOperation(_ operation: PSOperation, completion: @escaping (OperationConditionResult) -> Void) {
            completion(.satisfied)
        }
    }

    struct TestError: ConditionError {
        typealias Condition = TestCondition
    }
    
    func testConditionErrorConditionName() {
        let conditionError = TestError()
        
        XCTAssertEqual(conditionError.conditionName, TestError.Condition.name)
    }
}
