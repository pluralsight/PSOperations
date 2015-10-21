//
//  OperationErrorCodeTests.swift
//  PSOperations
//
//  Created by Matt McMurry on 10/1/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest

class OperationErrorCodeTests: XCTestCase {
    
    func testOperationErrorCodeEqualityLHS() {
        let opErrorCode = OperationErrorCode.ConditionFailed
        
        XCTAssertTrue(opErrorCode == 1)
    }
    
    func testOperationErrorCodeEqualityLHS_wrong() {
        let opErrorCode = OperationErrorCode.ConditionFailed
        
        XCTAssertFalse(opErrorCode == 2)
    }

    func testOperationErrorCodeEqualityRHS() {
        let opErrorCode = OperationErrorCode.ExecutionFailed
        
        XCTAssertTrue(2 == opErrorCode)
    }
    
    func testOperationErrorCodeEqualityRHS_wrong() {
        let opErrorCode = OperationErrorCode.ExecutionFailed
        
        XCTAssertFalse(1 == opErrorCode)
    }
}
