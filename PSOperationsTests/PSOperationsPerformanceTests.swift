//
//  PSOperationsPerformanceTests.swift
//  PSOperationsTests
//
//  Created by Matt McMurry on 4/16/18.
//  Copyright © 2018 Pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest

class PSOperationsPerformanceTests: XCTestCase {

    func testPSOperationPerformance() {
        let queue = PSOperationQueue()
        queue.isSuspended = true
        measure {
            for i in 0...1000 {
                let exp = expectation(description: "op #\(i)")
                let operation = PSBlockOperation(block: {
                    exp.fulfill()
                })
                
                queue.addOperation(operation)
            }
            
            queue.isSuspended = false
            waitForExpectations(timeout: 50, handler: nil)
        }
    }
}
