//
//  OperationConditionResultTests.swift
//  PSOperations
//
//  Created by Matt McMurry on 9/30/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

import XCTest
@testable import PSOperations

class OperationConditionResultTests: XCTestCase {
    
    func testOperationConditionResults_satisfied() {
        let sat1 = OperationConditionResult.satisfied
        let sat2 = OperationConditionResult.satisfied
        
        XCTAssertTrue(sat1 == sat2)
    }
    
    func testOperationConditionResults_Failed_SameError() {
        let error = NSError(domain: "test", code: 1, userInfo: nil)
        
        let failed1 = OperationConditionResult.failed(error)
        let failed2 = OperationConditionResult.failed(error)
        
        XCTAssertTrue(failed1 == failed2)
        
    }
    
    func testOperationConditionResults_Failed_DiffError() {
        let failed1 = OperationConditionResult.failed(NSError(domain: "test", code: 2, userInfo: nil))
        let failed2 = OperationConditionResult.failed(NSError(domain: "test", code: 1, userInfo: nil))
        
        XCTAssertFalse(failed1 == failed2)
        
    }
    
    func testOperationConditionResults_FailedAndSat() {
        let sat = OperationConditionResult.satisfied
        let failed2 = OperationConditionResult.failed(NSError(domain: "test", code: 1, userInfo: nil))
        
        XCTAssertFalse(sat == failed2)
        
    }
    
    func testOperationConditionResults_HasError() {
        let failed = OperationConditionResult.failed(NSError(domain: "test", code: 1, userInfo: nil))
        
        XCTAssertNotNil(failed.error)
    }
    
    func testOperationConditionResults_NoError() {
        let sat = OperationConditionResult.satisfied
        
        XCTAssertNil(sat.error)
    }    
}
