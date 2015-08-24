//
//  PSOperationsTests.swift
//  PSOperationsTests
//
//  Created by Dev Team on 6/17/15.
//  Copyright (c) 2015 pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest
import Photos

struct TestCondition: OperationCondition {
    
    static let name = "TestCondition"
    static let isMutuallyExclusive = false
    var dependencyOperation: NSOperation?

    var conditionBlock: () -> Bool = { true }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return dependencyOperation
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if conditionBlock() {
            completion(.Satisfied)
        } else {
            completion(.Failed(NSError(code: .ConditionFailed, userInfo: ["Failed": true])))
        }
    }
}

class PSOperationsTests: XCTestCase {
    
    override func setUp() {
        var dot: dispatch_once_t = 0
        dispatch_once(&dot, { () -> Void in
            
        })
    }
    
    func testStandardOperation() {
        
        let expectation = self.expectationWithDescription("block")
        
        let opQueue = OperationQueue()
        
        let op = NSBlockOperation { () -> Void in
            expectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testBlockOperation_noConditions_noDependencies() {
        
        let expectation = self.expectationWithDescription("block")
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testOperation_withPassingCondition_noDependencies() {
        
        let expectation = self.expectationWithDescription("block")
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
        }
        
        op.addCondition(TestCondition())
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOperation_withFailingCondition_noDependencies() {
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            XCTFail("Should not have run the block operation")
        }
        
        keyValueObservingExpectationForObject(op, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        XCTAssertFalse(op.cancelled, "Should not yet have cancelled the operation")
        
        var condition = TestCondition()

        condition.conditionBlock = {
            return false
        }
        
        op.addCondition(condition)
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOperation_withPassingCondition_andConditionDependency_noDependencies() {
        
        let expectation = self.expectationWithDescription("block")
        let expectation2 = self.expectationWithDescription("block2")
        
        var fulfilledExpectations = [XCTestExpectation]()
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
            fulfilledExpectations.append(expectation)
        }
        
        var testCondition = TestCondition()
        testCondition.dependencyOperation = BlockOperation {
            expectation2.fulfill()
            fulfilledExpectations.append(expectation2)
        }
        
        op.addCondition(testCondition)
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(fulfilledExpectations, [expectation2, expectation], "Expectations fulfilled out of order")
        }
    }
    
    func testOperation_noCondition_hasDependency() {
        let expectation = expectationWithDescription("block")
        let expectationDependency = expectationWithDescription("block2")
        
        var fulfilledExpectations = [XCTestExpectation]()
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
            fulfilledExpectations.append(expectation)
        }
        
        let opDependency = BlockOperation {
            expectationDependency.fulfill()
            fulfilledExpectations.append(expectationDependency)
        }
        
        op.addDependency(opDependency)
        
        opQueue.addOperation(op)
        opQueue.addOperation(opDependency)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(fulfilledExpectations, [expectationDependency, expectation], "Expectations fulfilled out of order")
        }
    }
    
    func testGroupOperation() {
        let exp1 = expectationWithDescription("block1")
        let exp2 = expectationWithDescription("block2")
        
        let op1 = NSBlockOperation {
            exp1.fulfill()
        }
        
        let op2 = NSBlockOperation {
            exp2.fulfill()
        }
        
        let groupOp = GroupOperation(operations: op1, op2)
        
        keyValueObservingExpectationForObject(groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(groupOp)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testGroupOperation_cancelBeforeExecuting() {
        let exp1 = expectationWithDescription("block1")
        let exp2 = expectationWithDescription("block2")
        
        let op1 = NSBlockOperation {
            XCTFail("should not execute -- cancelled")
        }
        
        op1.completionBlock = {
            exp1.fulfill()
        }
        
        let op2 = NSBlockOperation {
            XCTFail("should not execute -- cancelled")
        }
        
        op2.completionBlock = {
            exp2.fulfill()
        }
        
        let groupOp = GroupOperation(operations: op1, op2)
        
        keyValueObservingExpectationForObject(groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.suspended = true
        opQ.addOperation(groupOp)
        groupOp.cancel()
        opQ.suspended = false
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testDelayOperation() {
        let delay: NSTimeInterval = 0.1
        
        let then = NSDate()
        let op = DelayOperation(interval: delay)
        
        keyValueObservingExpectationForObject(op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        OperationQueue().addOperation(op)
        
        waitForExpectationsWithTimeout(delay + 1) {
            _ in
            let now = NSDate()
            let diff = now.timeIntervalSinceDate(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testMutualExclusion() {
        
        enum Test {}
        typealias TestMutualExclusion = MutuallyExclusive<Test>
        let cond = MutuallyExclusive<TestMutualExclusion>()
        
        var running = false
        
        let exp = expectationWithDescription("op2")
        
        let op = BlockOperation {
            running = true
            exp.fulfill()
        }
        op.addCondition(cond)
        
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 2
        
        let delayOp = DelayOperation(interval: 0.1)
        
        delayOp.addCondition(cond)
        
        keyValueObservingExpectationForObject(delayOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            
            XCTAssertFalse(running, "op should not yet have started execution")
            
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return true
        }

        opQ.addOperation(delayOp)
        opQ.addOperation(op)
        
        waitForExpectationsWithTimeout(0.9, handler: nil)
    }
    
    func testSilentCondition_failure() {
        
        var testCondition = TestCondition()
        
        testCondition.dependencyOperation = BlockOperation {
            XCTFail("should not run")
        }
        
        let exp = expectationWithDescription("")
        
        testCondition.conditionBlock = {
            exp.fulfill()
            return false
        }
        
        let silentCondition = SilentCondition(condition: testCondition)
        
        let opQ = OperationQueue()
        
        let operation = BlockOperation {
            XCTFail("should not run")
        }
        
        operation.addCondition(silentCondition)
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        opQ.addOperation(operation)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNegateCondition_failure() {
                
        let operation = BlockOperation {
            XCTFail("shouldn't run")
        }

        var testCondition = TestCondition()
        testCondition.conditionBlock = { true }

        let negateCondition = NegatedCondition(condition: testCondition)
        
        operation.addCondition(negateCondition)
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation)

        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNegateCondition_success() {
        
        let exp = expectationWithDescription("")
        
        let operation = BlockOperation {
            exp.fulfill()
        }
        
        var testCondition = TestCondition()
        testCondition.conditionBlock = { false }
        
        let negateCondition = NegatedCondition(condition: testCondition)
        
        operation.addCondition(negateCondition)
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNoCancelledDepsCondition_aDepCancels() {
        
        var dependencyOperation: BlockOperation?
        
        dependencyOperation = BlockOperation {
            dependencyOperation!.cancel()
        }
        
        let operation = BlockOperation {
            XCTFail("shouldn't run")
        }
        
        let noCancelledCondition = NoCancelledDependencies()
        operation.addCondition(noCancelledCondition)

        keyValueObservingExpectationForObject(dependencyOperation!, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        keyValueObservingExpectationForObject(opQ, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? NSOperationQueue {
                return opQ.operationCount == 0
            }
            
            return false
        }
        
        operation.addDependency(dependencyOperation!)
        
        opQ.addOperation(operation)
        opQ.addOperation(dependencyOperation!)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOperationRunsEvenIfDepCancels() {
        
        var dependencyOperation: BlockOperation?
        
        dependencyOperation = BlockOperation {
            dependencyOperation!.cancel()
        }
        
        let exp = expectationWithDescription("")
        
        let operation = BlockOperation {
            exp.fulfill()
        }
        
        keyValueObservingExpectationForObject(dependencyOperation!, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        
        let opQ = OperationQueue()
        
        operation.addDependency(dependencyOperation!)
        
        opQ.addOperation(operation)
        opQ.addOperation(dependencyOperation!)
        
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCancelledOperationLeavesQueue() {
        
        var operation: BlockOperation?
        
        operation = BlockOperation {
            operation!.cancel()
        }
        
        let exp = expectationWithDescription("")
        
        let operation2 = BlockOperation {
            exp.fulfill()
        }
        
        keyValueObservingExpectationForObject(operation!, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 1
        
        opQ.addOperation(operation!)
        opQ.addOperation(operation2)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCancelOperation_cancelBeforeStart() {
        let operation = BlockOperation {
            XCTFail("This should not run")
        }

        keyValueObservingExpectationForObject(operation, keyPath: "isFinished") {(op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }

            return false
        }

        let opQ = OperationQueue()
        opQ.suspended = true
        opQ.addOperation(operation)
        operation.cancel()
        opQ.suspended = false


        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertTrue(operation.cancelled, "")
            XCTAssertTrue(operation.finished, "")
        }
    }
    
    func testCancelOperation_cancelAfterStart() {
        let exp = expectationWithDescription("")
        
        var operation: BlockOperation?
        operation = BlockOperation {
            operation?.cancel()
            exp.fulfill()
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation!)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(opQ.operationCount, 0, "")
        }
    }
    
    func testBlockObserver() {
        let opQ = OperationQueue()
        
        var op: BlockOperation!
        op = BlockOperation {
            let producedOperation = BlockOperation {
                
            }
            
            op.produceOperation(producedOperation)
        }
        
        let exp1 = expectationWithDescription("1")
        let exp2 = expectationWithDescription("2")
        let exp3 = expectationWithDescription("3")
        
        let blockObserver = BlockObserver (
            startHandler: {
                _ in
                exp1.fulfill()
            },
            produceHandler: {
                _ in
                exp2.fulfill()
            },
            finishHandler: {
                _ in
                exp3.fulfill()
            }
        )
        
        op.addObserver(blockObserver)
        
        opQ.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testTimeoutObserver() {
        let delayOperation = DelayOperation(interval: 1)
        let timeoutObserver = TimeoutObserver(timeout: 0.1)
        
        delayOperation.addObserver(timeoutObserver)
        
        let opQ = OperationQueue()
        
        keyValueObservingExpectationForObject(delayOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        opQ.addOperation(delayOperation)
        
        waitForExpectationsWithTimeout(0.9, handler: nil)
    }
    
    func testNoCancelledDepsCondition_aDepCancels_inGroupOperation() {
        
        var dependencyOperation: BlockOperation?
        
        dependencyOperation = BlockOperation {
            dependencyOperation!.cancel()
        }
        
        let operation = BlockOperation {
            XCTFail("shouldn't run")
        }
        
        let noCancelledCondition = NoCancelledDependencies()
        operation.addCondition(noCancelledCondition)
        operation.addDependency(dependencyOperation!)
        
        let groupOp = GroupOperation(operations: [dependencyOperation!, operation])
        
        keyValueObservingExpectationForObject(dependencyOperation!, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        keyValueObservingExpectationForObject(groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        opQ.addOperation(groupOp)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(opQ.operationCount, 0, "")
        }
    }
    
    func testOperationCompletionBlock() {
        let executingExpectation = expectationWithDescription("block")
        let completionExpectation = expectationWithDescription("completion")
        
        let opQueue = OperationQueue()
        
        let op = NSBlockOperation { () -> Void in
            executingExpectation.fulfill()
        }
        
        op.completionBlock = {
            completionExpectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}
